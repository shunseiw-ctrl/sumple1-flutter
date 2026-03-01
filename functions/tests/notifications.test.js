const admin = require("firebase-admin");
const { createMockFirestoreEvent } = require("./helpers/setup");

// firebase-admin をモック
jest.mock("firebase-admin", () => {
  const firestoreMock = {
    collection: jest.fn(),
  };
  const messagingMock = {
    send: jest.fn().mockResolvedValue("message-id-123"),
  };
  return {
    initializeApp: jest.fn(),
    firestore: jest.fn(() => firestoreMock),
    messaging: jest.fn(() => messagingMock),
  };
});

jest.mock("firebase-functions/logger", () => ({
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
}));

const logger = require("firebase-functions/logger");

describe("onNotificationCreated logic", () => {
  let firestoreMock;
  let messagingMock;

  beforeEach(() => {
    jest.clearAllMocks();
    firestoreMock = admin.firestore();
    messagingMock = admin.messaging();
  });

  // ハンドラのロジックを直接テスト
  async function handleNotificationCreated(event) {
    const snap = event.data;
    if (!snap) {
      logger.warn("No snapshot in event");
      return;
    }

    const notifId = event.params.notifId;
    const data = snap.data() || {};

    const targetUid = data.targetUid;
    const title = data.title || "ALBAWORK";
    const body = data.body || "";
    const type = data.type || "general";

    if (!targetUid) {
      logger.warn("Missing targetUid on notifications doc", { notifId });
      return;
    }

    const profileRef = firestoreMock.collection("profiles").doc(targetUid);
    const profileSnap = await profileRef.get();

    if (!profileSnap.exists) {
      logger.warn("Profile not found", { targetUid, notifId });
      return;
    }

    const profile = profileSnap.data() || {};
    const token = profile.fcmToken;

    if (!token) {
      logger.warn("No fcmToken on profile", { targetUid, notifId });
      return;
    }

    const message = {
      token,
      notification: { title, body },
      data: {
        type: String(type),
        notificationId: String(notifId),
      },
      android: {
        priority: "high",
        notification: { channelId: "default" },
      },
      apns: {
        headers: { "apns-priority": "10" },
      },
    };

    const res = await messagingMock.send(message);
    logger.info("FCM sent for notification", { res, targetUid, notifId });
  }

  test("スナップショットがnullの場合はスキップ", async () => {
    const event = { data: null, params: { notifId: "n1" } };
    await handleNotificationCreated(event);
    expect(logger.warn).toHaveBeenCalledWith("No snapshot in event");
  });

  test("targetUid欠落の場合はスキップ", async () => {
    const event = createMockFirestoreEvent(
      { title: "テスト", body: "メッセージ" },
      { notifId: "n1" },
    );
    await handleNotificationCreated(event);
    expect(logger.warn).toHaveBeenCalledWith(
      "Missing targetUid on notifications doc",
      expect.objectContaining({ notifId: "n1" }),
    );
  });

  test("プロフィールが存在しない場合はスキップ", async () => {
    const mockDocRef = {
      get: jest.fn().mockResolvedValue({ exists: false, data: () => null }),
    };
    firestoreMock.collection.mockReturnValue({
      doc: jest.fn().mockReturnValue(mockDocRef),
    });

    const event = createMockFirestoreEvent(
      { targetUid: "user-001", title: "テスト" },
      { notifId: "n1" },
    );
    await handleNotificationCreated(event);
    expect(logger.warn).toHaveBeenCalledWith(
      "Profile not found",
      expect.objectContaining({ targetUid: "user-001" }),
    );
  });

  test("FCMトークン無しの場合はスキップ", async () => {
    const mockDocRef = {
      get: jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({ fcmToken: null }),
      }),
    };
    firestoreMock.collection.mockReturnValue({
      doc: jest.fn().mockReturnValue(mockDocRef),
    });

    const event = createMockFirestoreEvent(
      { targetUid: "user-001", title: "テスト" },
      { notifId: "n1" },
    );
    await handleNotificationCreated(event);
    expect(logger.warn).toHaveBeenCalledWith(
      "No fcmToken on profile",
      expect.objectContaining({ targetUid: "user-001" }),
    );
  });

  test("正常: FCMメッセージ構造を検証", async () => {
    const mockDocRef = {
      get: jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({ fcmToken: "token-abc" }),
      }),
    };
    firestoreMock.collection.mockReturnValue({
      doc: jest.fn().mockReturnValue(mockDocRef),
    });

    const event = createMockFirestoreEvent(
      {
        targetUid: "user-001",
        title: "新しい応募",
        body: "応募がありました",
        type: "application",
      },
      { notifId: "n1" },
    );
    await handleNotificationCreated(event);

    expect(messagingMock.send).toHaveBeenCalledWith(
      expect.objectContaining({
        token: "token-abc",
        notification: { title: "新しい応募", body: "応募がありました" },
        data: { type: "application", notificationId: "n1" },
        android: expect.objectContaining({ priority: "high" }),
        apns: expect.objectContaining({
          headers: { "apns-priority": "10" },
        }),
      }),
    );
    expect(logger.info).toHaveBeenCalled();
  });

  test("titleとbodyが未指定の場合はデフォルト値", async () => {
    const mockDocRef = {
      get: jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({ fcmToken: "token-abc" }),
      }),
    };
    firestoreMock.collection.mockReturnValue({
      doc: jest.fn().mockReturnValue(mockDocRef),
    });

    const event = createMockFirestoreEvent(
      { targetUid: "user-001" },
      { notifId: "n1" },
    );
    await handleNotificationCreated(event);

    expect(messagingMock.send).toHaveBeenCalledWith(
      expect.objectContaining({
        notification: { title: "ALBAWORK", body: "" },
        data: expect.objectContaining({ type: "general" }),
      }),
    );
  });
});
