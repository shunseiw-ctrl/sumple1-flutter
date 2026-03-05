const admin = require("firebase-admin");

// firebase-admin のモック
jest.mock("firebase-admin", () => {
  const firestoreMock = {
    collection: jest.fn(),
    batch: jest.fn(),
    runTransaction: jest.fn(),
  };
  const authMock = {
    deleteUser: jest.fn(),
    getUserByEmail: jest.fn(),
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

// rateLimiter モック
jest.mock("../src/rateLimiter", () => ({
  enforceRateLimit: jest.fn().mockResolvedValue(undefined),
  PRESETS: {
    auth: { maxRequests: 5, windowMs: 60000 },
    api: { maxRequests: 20, windowMs: 60000 },
    deletion: { maxRequests: 1, windowMs: 3600000 },
    merge: { maxRequests: 1, windowMs: 3600000 },
    payment: { maxRequests: 5, windowMs: 60000 },
  },
}));

const { mergeAccounts } = require("../src/accountMerge");

describe("mergeAccounts", () => {
  let db;
  let auth;

  const primaryUid = "primary-user-123";
  const deprecatedUid = "deprecated-user-456";
  const conflictingEmail = "old@example.com";

  const emptySnapshot = { empty: true, docs: [] };

  function createDocSnapshot(exists, data = {}) {
    return {
      exists,
      data: () => data,
      ref: {
        delete: jest.fn().mockResolvedValue(undefined),
        update: jest.fn().mockResolvedValue(undefined),
        set: jest.fn().mockResolvedValue(undefined),
        collection: jest.fn().mockReturnValue({
          doc: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue({ exists: false }),
            set: jest.fn().mockResolvedValue(undefined),
          }),
          get: jest.fn().mockResolvedValue(emptySnapshot),
          limit: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(emptySnapshot),
          }),
        }),
      },
    };
  }

  function createQuerySnapshot(docs) {
    return {
      empty: docs.length === 0,
      size: docs.length,
      docs: docs.map((d) => ({
        id: d._id || "doc-id",
        ref: {
          delete: jest.fn().mockResolvedValue(undefined),
          update: jest.fn().mockResolvedValue(undefined),
          set: jest.fn().mockResolvedValue(undefined),
          collection: jest.fn().mockReturnValue({
            limit: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue(emptySnapshot),
            }),
            where: jest.fn().mockReturnValue({
              limit: jest.fn().mockReturnValue({
                get: jest.fn().mockResolvedValue(emptySnapshot),
              }),
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
    auth.getUserByEmail.mockResolvedValue({ uid: deprecatedUid });

    const mockBatch = {
      delete: jest.fn(),
      update: jest.fn(),
      set: jest.fn(),
      commit: jest.fn().mockResolvedValue(undefined),
    };
    db.batch.mockReturnValue(mockBatch);

    // デフォルト: 全コレクションは空、config/admins なし
    db.collection.mockImplementation((name) => {
      if (name === "audit_logs") {
        return {
          add: jest.fn().mockResolvedValue({ id: "audit-log-1" }),
        };
      }
      if (name === "config") {
        return {
          doc: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(createDocSnapshot(false)),
          }),
        };
      }
      return {
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(createDocSnapshot(false)),
          delete: jest.fn().mockResolvedValue(undefined),
          set: jest.fn().mockResolvedValue(undefined),
          update: jest.fn().mockResolvedValue(undefined),
          collection: jest.fn().mockReturnValue({
            doc: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue({ exists: false }),
              set: jest.fn().mockResolvedValue(undefined),
            }),
            get: jest.fn().mockResolvedValue(emptySnapshot),
          }),
        }),
        where: jest.fn().mockReturnValue({
          limit: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(emptySnapshot),
          }),
          get: jest.fn().mockResolvedValue(emptySnapshot),
        }),
      };
    });
  });

  test("未認証ユーザーを拒否する", async () => {
    await expect(
      mergeAccounts.run({ auth: null, data: { conflictingEmail } }),
    ).rejects.toThrow("認証が必要です");
  });

  test("conflictingEmail がない場合を拒否する", async () => {
    await expect(
      mergeAccounts.run({ auth: { uid: primaryUid }, data: {} }),
    ).rejects.toThrow("conflictingEmail は必須です");
  });

  test("conflictingEmail が文字列でない場合を拒否する", async () => {
    await expect(
      mergeAccounts.run({
        auth: { uid: primaryUid },
        data: { conflictingEmail: 123 },
      }),
    ).rejects.toThrow("conflictingEmail は必須です");
  });

  test("同一UIDの統合を拒否する", async () => {
    auth.getUserByEmail.mockResolvedValue({ uid: primaryUid });

    await expect(
      mergeAccounts.run({
        auth: { uid: primaryUid },
        data: { conflictingEmail },
      }),
    ).rejects.toThrow("同一アカウントは統合できません");
  });

  test("管理者アカウントの統合を拒否する", async () => {
    db.collection.mockImplementation((name) => {
      if (name === "config") {
        return {
          doc: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(
              createDocSnapshot(true, { uids: [deprecatedUid] }),
            ),
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
          set: jest.fn().mockResolvedValue(undefined),
          collection: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(emptySnapshot),
          }),
        }),
        where: jest.fn().mockReturnValue({
          limit: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(emptySnapshot),
          }),
          get: jest.fn().mockResolvedValue(emptySnapshot),
        }),
      };
    });

    await expect(
      mergeAccounts.run({
        auth: { uid: primaryUid },
        data: { conflictingEmail },
      }),
    ).rejects.toThrow("管理者アカウントは統合できません");
  });

  test("データなしユーザーのマージが成功する", async () => {
    const result = await mergeAccounts.run({
      auth: { uid: primaryUid },
      data: { conflictingEmail },
    });

    expect(result).toEqual({ success: true });
    expect(auth.deleteUser).toHaveBeenCalledWith(deprecatedUid);
  });

  test("旧ユーザーが見つからない場合エラーを返す", async () => {
    auth.getUserByEmail.mockRejectedValue(new Error("User not found"));

    await expect(
      mergeAccounts.run({
        auth: { uid: primaryUid },
        data: { conflictingEmail },
      }),
    ).rejects.toThrow("指定されたメールアドレスのアカウントが見つかりません");
  });

  test("監査ログに accounts_merged を記録する", async () => {
    const auditAdd = jest.fn().mockResolvedValue({ id: "audit-log-1" });

    db.collection.mockImplementation((name) => {
      if (name === "audit_logs") {
        return { add: auditAdd };
      }
      if (name === "config") {
        return {
          doc: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(createDocSnapshot(false)),
          }),
        };
      }
      return {
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(createDocSnapshot(false)),
          delete: jest.fn().mockResolvedValue(undefined),
          set: jest.fn().mockResolvedValue(undefined),
          collection: jest.fn().mockReturnValue({
            doc: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue({ exists: false }),
              set: jest.fn().mockResolvedValue(undefined),
            }),
            get: jest.fn().mockResolvedValue(emptySnapshot),
          }),
        }),
        where: jest.fn().mockReturnValue({
          limit: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(emptySnapshot),
          }),
          get: jest.fn().mockResolvedValue(emptySnapshot),
        }),
      };
    });

    await mergeAccounts.run({
      auth: { uid: primaryUid },
      data: { conflictingEmail },
    });

    expect(auditAdd).toHaveBeenCalledWith(
      expect.objectContaining({
        action: "accounts_merged",
        actorUid: primaryUid,
        details: expect.objectContaining({
          primaryUid,
          deprecatedUid,
          conflictingEmail,
        }),
      }),
    );
  });

  test("旧Firebase Authユーザーを削除する", async () => {
    await mergeAccounts.run({
      auth: { uid: primaryUid },
      data: { conflictingEmail },
    });

    expect(auth.deleteUser).toHaveBeenCalledWith(deprecatedUid);
  });

  test("earnings の uid を更新する", async () => {
    const batchUpdate = jest.fn();
    const batchCommit = jest.fn().mockResolvedValue(undefined);
    db.batch.mockReturnValue({
      delete: jest.fn(),
      update: batchUpdate,
      set: jest.fn(),
      commit: batchCommit,
    });

    let earningsCallCount = 0;
    db.collection.mockImplementation((name) => {
      if (name === "earnings") {
        return {
          where: jest.fn().mockReturnValue({
            limit: jest.fn().mockReturnValue({
              get: jest.fn().mockImplementation(() => {
                earningsCallCount++;
                if (earningsCallCount === 1) {
                  return Promise.resolve(
                    createQuerySnapshot([{ uid: deprecatedUid, amount: 5000 }]),
                  );
                }
                return Promise.resolve(emptySnapshot);
              }),
            }),
          }),
        };
      }
      if (name === "config") {
        return {
          doc: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(createDocSnapshot(false)),
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
          set: jest.fn().mockResolvedValue(undefined),
          collection: jest.fn().mockReturnValue({
            doc: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue({ exists: false }),
              set: jest.fn().mockResolvedValue(undefined),
            }),
            get: jest.fn().mockResolvedValue(emptySnapshot),
          }),
        }),
        where: jest.fn().mockReturnValue({
          limit: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(emptySnapshot),
          }),
          get: jest.fn().mockResolvedValue(emptySnapshot),
        }),
      };
    });

    const result = await mergeAccounts.run({
      auth: { uid: primaryUid },
      data: { conflictingEmail },
    });

    expect(result).toEqual({ success: true });
    expect(batchUpdate).toHaveBeenCalledWith(expect.anything(), {
      uid: primaryUid,
    });
  });

  test("line_linked_accounts の firebaseUid を更新する", async () => {
    const batchUpdate = jest.fn();
    const batchCommit = jest.fn().mockResolvedValue(undefined);
    db.batch.mockReturnValue({
      delete: jest.fn(),
      update: batchUpdate,
      set: jest.fn(),
      commit: batchCommit,
    });

    db.collection.mockImplementation((name) => {
      if (name === "line_linked_accounts") {
        return {
          where: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(
              createQuerySnapshot([
                { firebaseUid: deprecatedUid, lineUserId: "line:U123" },
              ]),
            ),
            limit: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue(emptySnapshot),
            }),
          }),
        };
      }
      if (name === "config") {
        return {
          doc: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(createDocSnapshot(false)),
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
          set: jest.fn().mockResolvedValue(undefined),
          collection: jest.fn().mockReturnValue({
            doc: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue({ exists: false }),
              set: jest.fn().mockResolvedValue(undefined),
            }),
            get: jest.fn().mockResolvedValue(emptySnapshot),
          }),
        }),
        where: jest.fn().mockReturnValue({
          limit: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(emptySnapshot),
          }),
          get: jest.fn().mockResolvedValue(emptySnapshot),
        }),
      };
    });

    const result = await mergeAccounts.run({
      auth: { uid: primaryUid },
      data: { conflictingEmail },
    });

    expect(result).toEqual({ success: true });
    expect(batchUpdate).toHaveBeenCalledWith(expect.anything(), {
      firebaseUid: primaryUid,
    });
  });
});
