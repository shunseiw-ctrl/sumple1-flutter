const admin = require("firebase-admin");

// firebase-admin のモック
jest.mock("firebase-admin", () => {
  const firestoreMock = {
    collection: jest.fn(),
    batch: jest.fn(),
    runTransaction: jest.fn(),
  };
  return {
    initializeApp: jest.fn(),
    firestore: jest.fn(() => firestoreMock),
  };
});

admin.firestore.FieldValue = {
  serverTimestamp: jest.fn(() => "SERVER_TIMESTAMP"),
};

const {
  checkRateLimit,
  enforceRateLimit,
  enforceRateLimitForRequest,
  PRESETS,
} = require("../src/rateLimiter");

describe("rateLimiter", () => {
  let db;

  beforeEach(() => {
    jest.clearAllMocks();
    db = admin.firestore();
  });

  describe("checkRateLimit", () => {
    test("制限内のリクエストは許可される", async () => {
      const mockDocRef = {};
      db.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue(mockDocRef),
      });

      db.runTransaction.mockImplementation(async (fn) => {
        const transaction = {
          get: jest.fn().mockResolvedValue({
            exists: false,
          }),
          set: jest.fn(),
        };
        return fn(transaction);
      });

      const result = await checkRateLimit("test:user1", 5, 60000);
      expect(result).toBe(true);
    });

    test("制限超過のリクエストは拒否される", async () => {
      const now = Date.now();
      const recentTimestamps = Array.from({ length: 5 }, (_, i) => now - i * 1000);

      const mockDocRef = {};
      db.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue(mockDocRef),
      });

      db.runTransaction.mockImplementation(async (fn) => {
        const transaction = {
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({ timestamps: recentTimestamps }),
          }),
          set: jest.fn(),
        };
        return fn(transaction);
      });

      const result = await checkRateLimit("test:user1", 5, 60000);
      expect(result).toBe(false);
    });

    test("ウィンドウ期限切れのタイムスタンプは除外される", async () => {
      const now = Date.now();
      // 全て2分前のタイムスタンプ（1分ウィンドウ外）
      const oldTimestamps = Array.from({ length: 5 }, (_, i) => now - 120000 - i * 1000);

      const mockDocRef = {};
      db.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue(mockDocRef),
      });

      db.runTransaction.mockImplementation(async (fn) => {
        const transaction = {
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({ timestamps: oldTimestamps }),
          }),
          set: jest.fn(),
        };
        return fn(transaction);
      });

      const result = await checkRateLimit("test:user1", 5, 60000);
      expect(result).toBe(true);
    });

    test("新しいドキュメントの場合はタイムスタンプが記録される", async () => {
      const mockDocRef = {};
      let setCalledWith = null;

      db.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue(mockDocRef),
      });

      db.runTransaction.mockImplementation(async (fn) => {
        const transaction = {
          get: jest.fn().mockResolvedValue({
            exists: false,
          }),
          set: jest.fn((ref, data) => {
            setCalledWith = data;
          }),
        };
        return fn(transaction);
      });

      await checkRateLimit("test:newuser", 5, 60000);
      expect(setCalledWith).not.toBeNull();
      expect(setCalledWith.timestamps).toHaveLength(1);
    });
  });

  describe("enforceRateLimit", () => {
    test("制限超過時にHttpsErrorをスローする", async () => {
      const now = Date.now();
      const recentTimestamps = Array.from({ length: 5 }, (_, i) => now - i * 1000);

      db.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({}),
      });

      db.runTransaction.mockImplementation(async (fn) => {
        const transaction = {
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({ timestamps: recentTimestamps }),
          }),
          set: jest.fn(),
        };
        return fn(transaction);
      });

      await expect(
        enforceRateLimit("test:user1", 5, 60000),
      ).rejects.toThrow("リクエスト回数の上限に達しました");
    });
  });

  describe("enforceRateLimitForRequest", () => {
    test("制限超過時に429レスポンスを返す", async () => {
      const now = Date.now();
      const recentTimestamps = Array.from({ length: 5 }, (_, i) => now - i * 1000);

      db.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({}),
      });

      db.runTransaction.mockImplementation(async (fn) => {
        const transaction = {
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({ timestamps: recentTimestamps }),
          }),
          set: jest.fn(),
        };
        return fn(transaction);
      });

      const mockRes = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn(),
      };

      const result = await enforceRateLimitForRequest(
        mockRes,
        "test:user1",
        5,
        60000,
      );

      expect(result).toBe(false);
      expect(mockRes.status).toHaveBeenCalledWith(429);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({ error: "rate_limit_exceeded" }),
      );
    });

    test("制限内なら true を返す", async () => {
      db.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({}),
      });

      db.runTransaction.mockImplementation(async (fn) => {
        const transaction = {
          get: jest.fn().mockResolvedValue({ exists: false }),
          set: jest.fn(),
        };
        return fn(transaction);
      });

      const mockRes = {};
      const result = await enforceRateLimitForRequest(
        mockRes,
        "test:user1",
        5,
        60000,
      );

      expect(result).toBe(true);
    });
  });

  describe("PRESETS", () => {
    test("authプリセットは5 req/min", () => {
      expect(PRESETS.auth.maxRequests).toBe(5);
      expect(PRESETS.auth.windowMs).toBe(60000);
    });

    test("apiプリセットは20 req/min", () => {
      expect(PRESETS.api.maxRequests).toBe(20);
      expect(PRESETS.api.windowMs).toBe(60000);
    });

    test("deletionプリセットは1 req/hour", () => {
      expect(PRESETS.deletion.maxRequests).toBe(1);
      expect(PRESETS.deletion.windowMs).toBe(3600000);
    });

    test("paymentプリセットは5 req/min", () => {
      expect(PRESETS.payment.maxRequests).toBe(5);
      expect(PRESETS.payment.windowMs).toBe(60000);
    });
  });
});
