const admin = require("firebase-admin");

// firebase-admin のモック
jest.mock("firebase-admin", () => {
  const firestoreMock = {
    collection: jest.fn(),
    batch: jest.fn(),
  };
  const authMock = {
    deleteUser: jest.fn(),
  };
  return {
    initializeApp: jest.fn(),
    firestore: jest.fn(() => firestoreMock),
    auth: jest.fn(() => authMock),
  };
});

// FieldValue モック
admin.firestore.FieldValue = {
  serverTimestamp: jest.fn(() => "SERVER_TIMESTAMP"),
};

const { HttpsError } = require("firebase-functions/v2/https");

// テスト用モジュールインポート（firebase-admin モック後）
const { deleteUserData } = require("../src/accountDeletion");

describe("deleteUserData", () => {
  let db;
  let auth;

  // 共通のモックデータ
  const mockUid = "test-user-123";
  const mockAuth = { uid: mockUid };

  // ヘルパー: 空のクエリ結果
  const emptySnapshot = { empty: true, docs: [] };

  // ヘルパー: ドキュメントが存在するスナップショット
  function createDocSnapshot(exists, data = {}) {
    return {
      exists,
      data: () => data,
      ref: {
        delete: jest.fn().mockResolvedValue(undefined),
        collection: jest.fn().mockReturnValue({
          limit: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(emptySnapshot),
          }),
        }),
      },
    };
  }

  // ヘルパー: クエリ結果付きスナップショット
  function createQuerySnapshot(docs) {
    return {
      empty: docs.length === 0,
      size: docs.length,
      docs: docs.map((d) => ({
        ref: {
          delete: jest.fn().mockResolvedValue(undefined),
          update: jest.fn().mockResolvedValue(undefined),
          collection: jest.fn().mockReturnValue({
            limit: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue(emptySnapshot),
            }),
          }),
        },
        data: () => d,
      })),
    };
  }

  beforeEach(() => {
    jest.clearAllMocks();

    db = admin.firestore();
    auth = admin.auth();
    auth.deleteUser.mockResolvedValue(undefined);

    // デフォルト: 全コレクションは空
    const mockBatch = {
      delete: jest.fn(),
      update: jest.fn(),
      commit: jest.fn().mockResolvedValue(undefined),
    };
    db.batch.mockReturnValue(mockBatch);

    db.collection.mockImplementation((name) => {
      if (name === "audit_logs") {
        return {
          add: jest.fn().mockResolvedValue({ id: "audit-log-1" }),
        };
      }
      return {
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(createDocSnapshot(false)),
          delete: jest.fn().mockResolvedValue(undefined),
        }),
        where: jest.fn().mockReturnValue({
          limit: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(emptySnapshot),
          }),
        }),
      };
    });
  });

  test("未認証ユーザーを拒否する", async () => {
    const request = { auth: null, data: {} };

    // onCall の wrapped function を実行
    await expect(deleteUserData.run({ auth: null, data: {} })).rejects.toThrow(
      "認証が必要です",
    );
  });

  test("全コレクション削除が成功する（データなしユーザー）", async () => {
    const request = { auth: mockAuth, data: {} };

    const result = await deleteUserData.run(request);

    expect(result).toEqual({ success: true });
    expect(auth.deleteUser).toHaveBeenCalledWith(mockUid);
  });

  test("profiles/{uid} が存在する場合に削除する", async () => {
    const profileDoc = createDocSnapshot(true, {
      displayName: "Test User",
    });
    const profileDelete = jest.fn().mockResolvedValue(undefined);

    db.collection.mockImplementation((name) => {
      if (name === "profiles") {
        return {
          doc: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(profileDoc),
            delete: profileDelete,
          }),
          where: jest.fn().mockReturnValue({
            limit: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue(emptySnapshot),
            }),
          }),
        };
      }
      if (name === "audit_logs") {
        return {
          add: jest.fn().mockResolvedValue({ id: "audit-log-1" }),
        };
      }
      return {
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(createDocSnapshot(false)),
          delete: jest.fn().mockResolvedValue(undefined),
        }),
        where: jest.fn().mockReturnValue({
          limit: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(emptySnapshot),
          }),
        }),
      };
    });

    const result = await deleteUserData.run({
      auth: mockAuth,
      data: {},
    });

    expect(result).toEqual({ success: true });
    expect(profileDelete).toHaveBeenCalled();
  });

  test("applications を applicantUid でクエリ削除する", async () => {
    const batchDelete = jest.fn();
    const batchCommit = jest.fn().mockResolvedValue(undefined);
    db.batch.mockReturnValue({
      delete: batchDelete,
      update: jest.fn(),
      commit: batchCommit,
    });

    let callCount = 0;
    db.collection.mockImplementation((name) => {
      if (name === "applications") {
        return {
          doc: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(createDocSnapshot(false)),
          }),
          where: jest.fn().mockReturnValue({
            limit: jest.fn().mockReturnValue({
              get: jest.fn().mockImplementation(() => {
                callCount++;
                if (callCount === 1) {
                  return Promise.resolve(
                    createQuerySnapshot([{ applicantUid: mockUid }]),
                  );
                }
                return Promise.resolve(emptySnapshot);
              }),
            }),
          }),
        };
      }
      if (name === "audit_logs") {
        return {
          add: jest.fn().mockResolvedValue({ id: "audit-log-1" }),
        };
      }
      return {
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(createDocSnapshot(false)),
          delete: jest.fn().mockResolvedValue(undefined),
        }),
        where: jest.fn().mockReturnValue({
          limit: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(emptySnapshot),
          }),
        }),
      };
    });

    const result = await deleteUserData.run({
      auth: mockAuth,
      data: {},
    });

    expect(result).toEqual({ success: true });
    expect(batchDelete).toHaveBeenCalled();
    expect(batchCommit).toHaveBeenCalled();
  });

  test("payments を匿名化する（削除ではなく workerUid を変更）", async () => {
    const batchUpdate = jest.fn();
    const batchCommit = jest.fn().mockResolvedValue(undefined);
    db.batch.mockReturnValue({
      delete: jest.fn(),
      update: batchUpdate,
      commit: batchCommit,
    });

    let paymentsCallCount = 0;
    db.collection.mockImplementation((name) => {
      if (name === "payments") {
        return {
          where: jest.fn().mockReturnValue({
            limit: jest.fn().mockReturnValue({
              get: jest.fn().mockImplementation(() => {
                paymentsCallCount++;
                if (paymentsCallCount === 1) {
                  return Promise.resolve(
                    createQuerySnapshot([
                      { workerUid: mockUid, amount: 10000 },
                    ]),
                  );
                }
                return Promise.resolve(emptySnapshot);
              }),
            }),
          }),
        };
      }
      if (name === "audit_logs") {
        return {
          add: jest.fn().mockResolvedValue({ id: "audit-log-1" }),
        };
      }
      return {
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(createDocSnapshot(false)),
          delete: jest.fn().mockResolvedValue(undefined),
        }),
        where: jest.fn().mockReturnValue({
          limit: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(emptySnapshot),
          }),
        }),
      };
    });

    const result = await deleteUserData.run({
      auth: mockAuth,
      data: {},
    });

    expect(result).toEqual({ success: true });
    expect(batchUpdate).toHaveBeenCalledWith(expect.anything(), {
      workerUid: "deleted_user",
    });
  });

  test("chat サブコレクション messages を削除する", async () => {
    const msgBatchDelete = jest.fn();
    const msgBatchCommit = jest.fn().mockResolvedValue(undefined);

    let chatCallCount = 0;
    let batchCallCount = 0;

    db.batch.mockImplementation(() => {
      batchCallCount++;
      return {
        delete: msgBatchDelete,
        update: jest.fn(),
        commit: msgBatchCommit,
      };
    });

    db.collection.mockImplementation((name) => {
      if (name === "chats") {
        return {
          where: jest.fn().mockReturnValue({
            limit: jest.fn().mockReturnValue({
              get: jest.fn().mockImplementation(() => {
                chatCallCount++;
                if (chatCallCount === 1) {
                  const msgSnapshot = createQuerySnapshot([
                    { text: "hello", senderUid: mockUid },
                  ]);
                  return Promise.resolve({
                    empty: false,
                    size: 1,
                    docs: [
                      {
                        ref: {
                          delete: jest.fn().mockResolvedValue(undefined),
                          collection: jest.fn().mockReturnValue({
                            limit: jest.fn().mockReturnValue({
                              get: jest
                                .fn()
                                .mockResolvedValue(msgSnapshot),
                            }),
                          }),
                        },
                        data: () => ({ applicantUid: mockUid }),
                      },
                    ],
                  });
                }
                return Promise.resolve(emptySnapshot);
              }),
            }),
          }),
        };
      }
      if (name === "audit_logs") {
        return {
          add: jest.fn().mockResolvedValue({ id: "audit-log-1" }),
        };
      }
      return {
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(createDocSnapshot(false)),
          delete: jest.fn().mockResolvedValue(undefined),
        }),
        where: jest.fn().mockReturnValue({
          limit: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(emptySnapshot),
          }),
        }),
      };
    });

    const result = await deleteUserData.run({
      auth: mockAuth,
      data: {},
    });

    expect(result).toEqual({ success: true });
    // messages のバッチ削除が呼ばれたことを確認
    expect(msgBatchDelete).toHaveBeenCalled();
  });

  test("audit_log に削除イベントを記録する", async () => {
    const auditAdd = jest.fn().mockResolvedValue({ id: "audit-log-1" });

    db.collection.mockImplementation((name) => {
      if (name === "audit_logs") {
        return { add: auditAdd };
      }
      return {
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(createDocSnapshot(false)),
          delete: jest.fn().mockResolvedValue(undefined),
        }),
        where: jest.fn().mockReturnValue({
          limit: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(emptySnapshot),
          }),
        }),
      };
    });

    await deleteUserData.run({ auth: mockAuth, data: {} });

    expect(auditAdd).toHaveBeenCalledWith(
      expect.objectContaining({
        action: "account_deleted",
        actorUid: mockUid,
        targetCollection: "profiles",
        targetDocId: mockUid,
        details: { reason: "user_requested" },
      }),
    );
  });

  test("Firebase Auth アカウントを削除する", async () => {
    const result = await deleteUserData.run({
      auth: mockAuth,
      data: {},
    });

    expect(result).toEqual({ success: true });
    expect(auth.deleteUser).toHaveBeenCalledWith(mockUid);
  });

  test("favorites/{uid} が存在する場合に削除する", async () => {
    const favDelete = jest.fn().mockResolvedValue(undefined);

    db.collection.mockImplementation((name) => {
      if (name === "favorites") {
        return {
          doc: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(createDocSnapshot(true, { jobs: ["j1"] })),
            delete: favDelete,
          }),
        };
      }
      if (name === "audit_logs") {
        return {
          add: jest.fn().mockResolvedValue({ id: "audit-log-1" }),
        };
      }
      return {
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(createDocSnapshot(false)),
          delete: jest.fn().mockResolvedValue(undefined),
        }),
        where: jest.fn().mockReturnValue({
          limit: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(emptySnapshot),
          }),
        }),
      };
    });

    const result = await deleteUserData.run({
      auth: mockAuth,
      data: {},
    });

    expect(result).toEqual({ success: true });
    expect(favDelete).toHaveBeenCalled();
  });

  test("内部エラー時に HttpsError を投げる", async () => {
    auth.deleteUser.mockRejectedValue(new Error("Auth error"));

    await expect(
      deleteUserData.run({ auth: mockAuth, data: {} }),
    ).rejects.toThrow("アカウント削除に失敗しました");
  });
});
