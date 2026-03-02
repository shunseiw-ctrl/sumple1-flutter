const admin = require("firebase-admin");

// firebase-admin のモック
jest.mock("firebase-admin", () => {
  const firestoreMock = {
    collection: jest.fn(),
  };
  return {
    initializeApp: jest.fn(),
    firestore: jest.fn(() => firestoreMock),
  };
});

admin.firestore.FieldValue = {
  serverTimestamp: jest.fn(() => "SERVER_TIMESTAMP"),
};

// rateLimiter モック（レート制限はrateLimiter.test.jsでテスト済み）
jest.mock("../src/rateLimiter", () => ({
  enforceRateLimit: jest.fn().mockResolvedValue(undefined),
  PRESETS: {
    auth: { maxRequests: 5, windowMs: 60000 },
    api: { maxRequests: 20, windowMs: 60000 },
    deletion: { maxRequests: 1, windowMs: 3600000 },
    payment: { maxRequests: 5, windowMs: 60000 },
  },
}));

const { exportUserData } = require("../src/dataExport");

describe("exportUserData", () => {
  let db;
  const mockUid = "export-user-123";
  const mockAuth = { uid: mockUid };

  const emptySnapshot = { empty: true, docs: [] };

  function createDocSnapshot(exists, data = {}) {
    return {
      exists,
      data: () => data,
      ref: {
        collection: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(emptySnapshot),
        }),
      },
    };
  }

  beforeEach(() => {
    jest.clearAllMocks();
    db = admin.firestore();

    // デフォルト: 全コレクションは空
    db.collection.mockImplementation((name) => {
      if (name === "audit_logs") {
        return { add: jest.fn().mockResolvedValue({ id: "log-1" }) };
      }
      return {
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(createDocSnapshot(false)),
        }),
        where: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(emptySnapshot),
        }),
      };
    });
  });

  test("未認証ユーザーを拒否する", async () => {
    await expect(
      exportUserData.run({ auth: null, data: {} }),
    ).rejects.toThrow("認証が必要です");
  });

  test("空ユーザーは空データを返す", async () => {
    const result = await exportUserData.run({
      auth: mockAuth,
      data: {},
    });

    expect(result.uid).toBe(mockUid);
    expect(result.profile).toBeNull();
    expect(result.applications).toEqual([]);
    expect(result.earnings).toEqual([]);
    expect(result.chats).toEqual([]);
    expect(result.ratings).toEqual([]);
    expect(result.favorites).toBeNull();
    expect(result.notifications).toEqual([]);
    expect(result.contacts).toEqual([]);
    expect(result.payments).toEqual([]);
    expect(result.exportedAt).toBeDefined();
  });

  test("プロフィールデータを返却する", async () => {
    db.collection.mockImplementation((name) => {
      if (name === "profiles") {
        return {
          doc: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(
              createDocSnapshot(true, {
                displayName: "Test User",
                email: "test@example.com",
                fcmToken: "secret-token",
                stripeAccountId: "acct_xxx",
              }),
            ),
          }),
        };
      }
      if (name === "audit_logs") {
        return { add: jest.fn().mockResolvedValue({ id: "log-1" }) };
      }
      return {
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(createDocSnapshot(false)),
        }),
        where: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(emptySnapshot),
        }),
      };
    });

    const result = await exportUserData.run({
      auth: mockAuth,
      data: {},
    });

    expect(result.profile.displayName).toBe("Test User");
    expect(result.profile.email).toBe("test@example.com");
  });

  test("機密フィールド fcmToken を除外する", async () => {
    db.collection.mockImplementation((name) => {
      if (name === "profiles") {
        return {
          doc: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(
              createDocSnapshot(true, {
                displayName: "Test",
                fcmToken: "secret-token",
              }),
            ),
          }),
        };
      }
      if (name === "audit_logs") {
        return { add: jest.fn().mockResolvedValue({ id: "log-1" }) };
      }
      return {
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(createDocSnapshot(false)),
        }),
        where: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(emptySnapshot),
        }),
      };
    });

    const result = await exportUserData.run({
      auth: mockAuth,
      data: {},
    });

    expect(result.profile.fcmToken).toBeUndefined();
  });

  test("機密フィールド stripeAccountId を除外する", async () => {
    db.collection.mockImplementation((name) => {
      if (name === "profiles") {
        return {
          doc: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(
              createDocSnapshot(true, {
                displayName: "Test",
                stripeAccountId: "acct_xxx",
              }),
            ),
          }),
        };
      }
      if (name === "audit_logs") {
        return { add: jest.fn().mockResolvedValue({ id: "log-1" }) };
      }
      return {
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(createDocSnapshot(false)),
        }),
        where: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(emptySnapshot),
        }),
      };
    });

    const result = await exportUserData.run({
      auth: mockAuth,
      data: {},
    });

    expect(result.profile.stripeAccountId).toBeUndefined();
  });

  test("全コレクションデータを正しく返却する", async () => {
    db.collection.mockImplementation((name) => {
      if (name === "profiles") {
        return {
          doc: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(
              createDocSnapshot(true, { displayName: "User" }),
            ),
          }),
        };
      }
      if (name === "applications") {
        return {
          where: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue({
              docs: [
                {
                  id: "app-1",
                  data: () => ({ status: "applied", jobId: "j1" }),
                },
              ],
            }),
          }),
        };
      }
      if (name === "favorites") {
        return {
          doc: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(
              createDocSnapshot(true, { jobs: ["j1", "j2"] }),
            ),
          }),
        };
      }
      if (name === "audit_logs") {
        return { add: jest.fn().mockResolvedValue({ id: "log-1" }) };
      }
      return {
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(createDocSnapshot(false)),
        }),
        where: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(emptySnapshot),
        }),
      };
    });

    const result = await exportUserData.run({
      auth: mockAuth,
      data: {},
    });

    expect(result.profile).toEqual({ displayName: "User" });
    expect(result.applications).toHaveLength(1);
    expect(result.applications[0].id).toBe("app-1");
    expect(result.favorites).toEqual({ jobs: ["j1", "j2"] });
  });

  test("audit_log にエクスポートイベントを記録する", async () => {
    const auditAdd = jest.fn().mockResolvedValue({ id: "log-1" });

    db.collection.mockImplementation((name) => {
      if (name === "audit_logs") {
        return { add: auditAdd };
      }
      return {
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(createDocSnapshot(false)),
        }),
        where: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(emptySnapshot),
        }),
      };
    });

    await exportUserData.run({ auth: mockAuth, data: {} });

    expect(auditAdd).toHaveBeenCalledWith(
      expect.objectContaining({
        action: "data_exported",
        actorUid: mockUid,
      }),
    );
  });

  test("内部エラー時に HttpsError を投げる", async () => {
    db.collection.mockImplementation(() => {
      throw new Error("Firestore error");
    });

    await expect(
      exportUserData.run({ auth: mockAuth, data: {} }),
    ).rejects.toThrow("データエクスポートに失敗しました");
  });
});
