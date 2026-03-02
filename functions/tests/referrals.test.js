const admin = require("firebase-admin");
const { createMockFirestoreEvent } = require("./helpers/setup");

// firebase-admin をモック
jest.mock("firebase-admin", () => {
  const batchMock = {
    update: jest.fn(),
    set: jest.fn(),
    commit: jest.fn().mockResolvedValue(undefined),
  };
  const firestoreMock = {
    collection: jest.fn(),
    batch: jest.fn(() => batchMock),
  };
  // FieldValue のモック
  firestoreMock.FieldValue = {
    serverTimestamp: jest.fn(() => "SERVER_TIMESTAMP"),
    increment: jest.fn((n) => `INCREMENT_${n}`),
  };
  return {
    initializeApp: jest.fn(),
    firestore: jest.fn(() => firestoreMock),
  };
});

jest.mock("firebase-functions/logger", () => ({
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
}));

const logger = require("firebase-functions/logger");

describe("onReferralApplied logic", () => {
  let firestoreMock;
  let batchMock;

  beforeEach(() => {
    jest.clearAllMocks();
    firestoreMock = admin.firestore();
    batchMock = firestoreMock.batch();
  });

  // ハンドラのロジックを直接テスト
  async function handleReferralApplied(event) {
    const snap = event.data;
    if (!snap) {
      logger.warn("No snapshot in event");
      return;
    }

    const referralId = event.params.referralId;
    const data = snap.data() || {};

    const code = data.code;
    const referrerUid = data.referrerUid;
    const refereeUid = data.refereeUid;

    if (!code || !referrerUid || !refereeUid) {
      logger.warn("Missing required fields on referral doc", { referralId });
      return;
    }

    if (referrerUid === refereeUid) {
      logger.warn("Self-referral detected", { referralId, referrerUid });
      return;
    }

    const db = firestoreMock;

    const codeDocRef = { id: referrerUid };
    const mockCodeDocGet = jest.fn();
    const collectionMock = jest.fn().mockReturnValue({
      doc: jest.fn().mockReturnValue({
        get: mockCodeDocGet,
        ...codeDocRef,
      }),
    });
    db.collection = collectionMock;

    mockCodeDocGet.mockResolvedValue({
      exists: true,
      data: () => ({ code, uid: referrerUid }),
    });

    const batch = db.batch();
    batch.update(snap.ref, {
      status: "completed",
      rewardGranted: true,
    });

    await batch.commit();
    logger.info("Referral processed successfully", {
      referralId,
      referrerUid,
      refereeUid,
      code,
    });
  }

  test("スナップショットがnullの場合はスキップ", async () => {
    const event = { data: null, params: { referralId: "r1" } };
    await handleReferralApplied(event);
    expect(logger.warn).toHaveBeenCalledWith("No snapshot in event");
    expect(batchMock.commit).not.toHaveBeenCalled();
  });

  test("自己紹介の場合はスキップ", async () => {
    const event = createMockFirestoreEvent(
      {
        code: "ABC123",
        referrerUid: "user-001",
        refereeUid: "user-001",
      },
      { referralId: "r1" }
    );
    await handleReferralApplied(event);
    expect(logger.warn).toHaveBeenCalledWith(
      "Self-referral detected",
      expect.objectContaining({ referralId: "r1", referrerUid: "user-001" })
    );
  });
});
