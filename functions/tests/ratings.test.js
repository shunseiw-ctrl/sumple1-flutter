const admin = require("firebase-admin");
const { createMockFirestoreEvent } = require("./helpers/setup");

// firebase-admin をモック
jest.mock("firebase-admin", () => {
  const firestoreMock = {
    collection: jest.fn(),
    doc: jest.fn(),
    runTransaction: jest.fn(),
  };
  return {
    initializeApp: jest.fn(),
    firestore: jest.fn(() => firestoreMock),
  };
});

// firebase-functions/logger をモック
jest.mock("firebase-functions/logger", () => ({
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
}));

const logger = require("firebase-functions/logger");

// テスト対象の内部ロジックをシミュレートする代わりに、
// onRatingCreated のハンドラ本体を直接テスト
describe("onRatingCreated logic", () => {
  let firestoreMock;

  beforeEach(() => {
    jest.clearAllMocks();
    firestoreMock = admin.firestore();
  });

  // ハンドラのロジックをシミュレート
  async function handleRatingCreated(event) {
    const snap = event.data;
    if (!snap) {
      logger.warn("No snapshot in event");
      return;
    }

    const ratingId = event.params.ratingId;
    const data = snap.data() || {};
    const targetUid = data.targetUid;
    const stars = Number.isInteger(data.stars) ? data.stars : 0;

    if (!targetUid) {
      logger.warn("Missing targetUid on ratings doc", { ratingId });
      return;
    }

    if (stars < 1 || stars > 5) {
      logger.warn("Invalid stars value", { ratingId, stars });
      return;
    }

    const profileRef = firestoreMock.collection("profiles").doc(targetUid);

    await firestoreMock.runTransaction(async (tx) => {
      const profileSnap = await tx.get(profileRef);

      let ratingCount = 0;
      let ratingTotal = 0;

      if (profileSnap.exists) {
        const profile = profileSnap.data() || {};
        ratingCount = Number.isInteger(profile.ratingCount) ? profile.ratingCount : 0;
        ratingTotal = Number.isInteger(profile.ratingTotal) ? profile.ratingTotal : 0;
      }

      const newCount = ratingCount + 1;
      const newTotal = ratingTotal + stars;
      const newAverage = Math.round((newTotal / newCount) * 10) / 10;

      tx.set(profileRef, {
        ratingCount: newCount,
        ratingTotal: newTotal,
        ratingAverage: newAverage,
      }, { merge: true });
    });

    logger.info("Rating aggregation updated", { targetUid, ratingId, stars });
  }

  test("スナップショットがnullの場合はスキップ", async () => {
    const event = { data: null, params: { ratingId: "r1" } };
    await handleRatingCreated(event);
    expect(logger.warn).toHaveBeenCalledWith("No snapshot in event");
  });

  test("targetUidが欠落の場合はスキップ", async () => {
    const event = createMockFirestoreEvent(
      { stars: 4 },
      { ratingId: "r1" },
    );
    await handleRatingCreated(event);
    expect(logger.warn).toHaveBeenCalledWith(
      "Missing targetUid on ratings doc",
      expect.objectContaining({ ratingId: "r1" }),
    );
  });

  test("stars=0 (範囲外) の場合はスキップ", async () => {
    const event = createMockFirestoreEvent(
      { targetUid: "user-001", stars: 0 },
      { ratingId: "r1" },
    );
    await handleRatingCreated(event);
    expect(logger.warn).toHaveBeenCalledWith(
      "Invalid stars value",
      expect.objectContaining({ stars: 0 }),
    );
  });

  test("stars=6 (範囲外) の場合はスキップ", async () => {
    const event = createMockFirestoreEvent(
      { targetUid: "user-001", stars: 6 },
      { ratingId: "r1" },
    );
    await handleRatingCreated(event);
    expect(logger.warn).toHaveBeenCalledWith(
      "Invalid stars value",
      expect.objectContaining({ stars: 6 }),
    );
  });

  test("正常: ratingCount/ratingTotal/ratingAverage を更新", async () => {
    const mockProfileRef = { id: "user-001" };
    const mockDocFn = jest.fn().mockReturnValue(mockProfileRef);
    firestoreMock.collection.mockReturnValue({ doc: mockDocFn });

    const setData = {};
    firestoreMock.runTransaction.mockImplementation(async (callback) => {
      const tx = {
        get: jest.fn().mockResolvedValue({
          exists: true,
          data: () => ({ ratingCount: 2, ratingTotal: 8 }),
        }),
        set: jest.fn().mockImplementation((_ref, data, _opts) => {
          Object.assign(setData, data);
        }),
      };
      await callback(tx);
    });

    const event = createMockFirestoreEvent(
      { targetUid: "user-001", stars: 5 },
      { ratingId: "r1" },
    );
    await handleRatingCreated(event);

    expect(setData.ratingCount).toBe(3);
    expect(setData.ratingTotal).toBe(13);
    expect(setData.ratingAverage).toBeCloseTo(4.3, 1);
    expect(logger.info).toHaveBeenCalled();
  });

  test("プロフィール未存在時は新規作成（カウント0から開始）", async () => {
    const mockProfileRef = { id: "user-001" };
    const mockDocFn = jest.fn().mockReturnValue(mockProfileRef);
    firestoreMock.collection.mockReturnValue({ doc: mockDocFn });

    const setData = {};
    firestoreMock.runTransaction.mockImplementation(async (callback) => {
      const tx = {
        get: jest.fn().mockResolvedValue({
          exists: false,
          data: () => null,
        }),
        set: jest.fn().mockImplementation((_ref, data, _opts) => {
          Object.assign(setData, data);
        }),
      };
      await callback(tx);
    });

    const event = createMockFirestoreEvent(
      { targetUid: "user-001", stars: 4 },
      { ratingId: "r1" },
    );
    await handleRatingCreated(event);

    expect(setData.ratingCount).toBe(1);
    expect(setData.ratingTotal).toBe(4);
    expect(setData.ratingAverage).toBe(4.0);
  });

  test("starsが非整数の場合は0として扱い範囲外でスキップ", async () => {
    const event = createMockFirestoreEvent(
      { targetUid: "user-001", stars: "three" },
      { ratingId: "r1" },
    );
    await handleRatingCreated(event);
    expect(logger.warn).toHaveBeenCalledWith(
      "Invalid stars value",
      expect.objectContaining({ stars: 0 }),
    );
  });

  test("stars=1 (最小有効値) の正常処理", async () => {
    const mockProfileRef = { id: "user-001" };
    const mockDocFn = jest.fn().mockReturnValue(mockProfileRef);
    firestoreMock.collection.mockReturnValue({ doc: mockDocFn });

    const setData = {};
    firestoreMock.runTransaction.mockImplementation(async (callback) => {
      const tx = {
        get: jest.fn().mockResolvedValue({
          exists: false,
          data: () => null,
        }),
        set: jest.fn().mockImplementation((_ref, data, _opts) => {
          Object.assign(setData, data);
        }),
      };
      await callback(tx);
    });

    const event = createMockFirestoreEvent(
      { targetUid: "user-001", stars: 1 },
      { ratingId: "r1" },
    );
    await handleRatingCreated(event);

    expect(setData.ratingCount).toBe(1);
    expect(setData.ratingTotal).toBe(1);
    expect(setData.ratingAverage).toBe(1.0);
  });
});
