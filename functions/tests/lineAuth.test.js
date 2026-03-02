const admin = require("firebase-admin");

// --- firebase-admin モック ---
jest.mock("firebase-admin", () => {
  const firestoreMock = {
    doc: jest.fn(),
    collection: jest.fn(),
  };
  const firestoreFn = jest.fn(() => firestoreMock);
  firestoreFn.FieldValue = {
    serverTimestamp: jest.fn(() => ({ __serverTimestamp: true })),
  };

  const authMock = {
    getUser: jest.fn(),
    createUser: jest.fn(),
    updateUser: jest.fn(),
    createCustomToken: jest.fn(),
  };

  return {
    initializeApp: jest.fn(),
    firestore: firestoreFn,
    auth: jest.fn(() => authMock),
  };
});

// firebase-functions v2 モック
jest.mock("firebase-functions/v2/https", () => ({
  onRequest: jest.fn((opts, handler) => handler),
  onCall: jest.fn((opts, handler) => handler),
  HttpsError: class HttpsError extends Error {
    constructor(code, message) {
      super(message);
      this.code = code;
    }
  },
}));

jest.mock("firebase-functions/v2/scheduler", () => ({
  onSchedule: jest.fn((opts, handler) => handler),
}));

jest.mock("firebase-functions/logger", () => ({
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
}));

// https モック
jest.mock("https", () => ({
  request: jest.fn(),
}));

// rateLimiter モック（レート制限はrateLimiter.test.jsでテスト済み）
jest.mock("../src/rateLimiter", () => ({
  enforceRateLimitForRequest: jest.fn().mockResolvedValue(true),
  enforceRateLimit: jest.fn().mockResolvedValue(undefined),
  PRESETS: {
    auth: { maxRequests: 5, windowMs: 60000 },
    api: { maxRequests: 20, windowMs: 60000 },
    deletion: { maxRequests: 1, windowMs: 3600000 },
    payment: { maxRequests: 5, windowMs: 60000 },
  },
}));

const lineAuth = require("../src/lineAuth");

describe("lineAuth", () => {
  let db;

  beforeEach(() => {
    jest.clearAllMocks();
    db = admin.firestore();
  });

  // --- lineAuthStart ---
  describe("lineAuthStart", () => {
    it("should redirect to LINE auth URL with state saved to Firestore", async () => {
      const setMock = jest.fn().mockResolvedValue(undefined);
      const docMock = jest.fn().mockReturnValue({ set: setMock });
      db.collection.mockReturnValue({ doc: docMock });

      process.env.LINE_CHANNEL_ID = "test-channel-id";

      const req = {
        protocol: "https",
        hostname: "alba-work.web.app",
      };
      const res = {
        redirect: jest.fn(),
        status: jest.fn().mockReturnThis(),
        send: jest.fn(),
      };

      await lineAuth.lineAuthStart(req, res);

      expect(db.collection).toHaveBeenCalledWith("line_auth_states");
      expect(setMock).toHaveBeenCalled();
      expect(res.redirect).toHaveBeenCalledWith(
        302,
        expect.stringContaining("access.line.me/oauth2/v2.1/authorize"),
      );

      delete process.env.LINE_CHANNEL_ID;
    });

    it("should return 500 when LINE_CHANNEL_ID is not set", async () => {
      delete process.env.LINE_CHANNEL_ID;

      const req = { protocol: "https", hostname: "test.com" };
      const res = {
        redirect: jest.fn(),
        status: jest.fn().mockReturnThis(),
        send: jest.fn(),
      };

      await lineAuth.lineAuthStart(req, res);

      expect(res.status).toHaveBeenCalledWith(500);
      expect(res.send).toHaveBeenCalledWith("Server configuration error");
    });
  });

  // --- lineAuthCallback ---
  describe("lineAuthCallback", () => {
    it("should redirect with error when LINE returns error", async () => {
      const req = {
        query: { error: "access_denied", error_description: "User denied" },
        protocol: "https",
        hostname: "alba-work.web.app",
      };
      const res = { redirect: jest.fn() };

      await lineAuth.lineAuthCallback(req, res);

      expect(res.redirect).toHaveBeenCalledWith(
        302,
        "https://alba-work.web.app/#line_error=auth_denied",
      );
    });

    it("should redirect with error when state is missing", async () => {
      const req = {
        query: { code: "test-code" },
        protocol: "https",
        hostname: "alba-work.web.app",
      };
      const res = { redirect: jest.fn() };

      await lineAuth.lineAuthCallback(req, res);

      expect(res.redirect).toHaveBeenCalledWith(
        302,
        "https://alba-work.web.app/#line_error=invalid_state",
      );
    });

    it("should redirect with error when state not found in Firestore", async () => {
      const getMock = jest.fn().mockResolvedValue({ exists: false });
      const docMock = jest.fn().mockReturnValue({ get: getMock, delete: jest.fn() });
      db.collection.mockReturnValue({ doc: docMock });

      const req = {
        query: { code: "test-code", state: "invalid-state" },
        protocol: "https",
        hostname: "alba-work.web.app",
      };
      const res = { redirect: jest.fn() };

      await lineAuth.lineAuthCallback(req, res);

      expect(res.redirect).toHaveBeenCalledWith(
        302,
        "https://alba-work.web.app/#line_error=invalid_state",
      );
    });

    it("should redirect with error when state is expired", async () => {
      const deleteMock = jest.fn().mockResolvedValue(undefined);
      const getMock = jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({
          expiresAt: { toDate: () => new Date(Date.now() - 1000) },
          callbackUrl: "https://alba-work.web.app/auth/line/callback",
        }),
      });
      const docMock = jest.fn().mockReturnValue({ get: getMock, delete: deleteMock });
      db.collection.mockReturnValue({ doc: docMock });

      const req = {
        query: { code: "test-code", state: "expired-state" },
        protocol: "https",
        hostname: "alba-work.web.app",
      };
      const res = { redirect: jest.fn() };

      await lineAuth.lineAuthCallback(req, res);

      expect(deleteMock).toHaveBeenCalled();
      expect(res.redirect).toHaveBeenCalledWith(
        302,
        "https://alba-work.web.app/#line_error=state_expired",
      );
    });
  });

  // --- lineAuthExchange ---
  describe("lineAuthExchange", () => {
    it("should return 405 for non-POST requests", async () => {
      const req = { method: "GET", body: {} };
      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn(),
      };

      await lineAuth.lineAuthExchange(req, res);

      expect(res.status).toHaveBeenCalledWith(405);
      expect(res.json).toHaveBeenCalledWith({ error: "method_not_allowed" });
    });

    it("should return 400 when code is missing", async () => {
      const req = { method: "POST", body: {}, headers: {} };
      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn(),
      };

      await lineAuth.lineAuthExchange(req, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({ error: "missing_code" });
    });

    it("should return 400 when code is invalid (not found in Firestore)", async () => {
      const getMock = jest.fn().mockResolvedValue({ exists: false });
      const docMock = jest.fn().mockReturnValue({ get: getMock, delete: jest.fn() });
      db.collection.mockReturnValue({ doc: docMock });

      const req = { method: "POST", body: { code: "invalid-code" }, headers: {} };
      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn(),
      };

      await lineAuth.lineAuthExchange(req, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({ error: "invalid_code" });
    });

    it("should return 400 when code is expired", async () => {
      const deleteMock = jest.fn().mockResolvedValue(undefined);
      const getMock = jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({
          customToken: "custom-token",
          profile: { displayName: "Test" },
          expiresAt: { toDate: () => new Date(Date.now() - 1000) },
        }),
      });
      const docMock = jest.fn().mockReturnValue({ get: getMock, delete: deleteMock });
      db.collection.mockReturnValue({ doc: docMock });

      const req = { method: "POST", body: { code: "expired-code" }, headers: {} };
      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn(),
      };

      await lineAuth.lineAuthExchange(req, res);

      expect(deleteMock).toHaveBeenCalled();
      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({ error: "code_expired" });
    });

    it("should return customToken and profile for valid code", async () => {
      const deleteMock = jest.fn().mockResolvedValue(undefined);
      const getMock = jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({
          customToken: "valid-custom-token",
          profile: { displayName: "LINE User", photoUrl: "https://example.com/photo.jpg", provider: "line" },
          expiresAt: { toDate: () => new Date(Date.now() + 60000) },
        }),
      });
      const docMock = jest.fn().mockReturnValue({ get: getMock, delete: deleteMock });
      db.collection.mockReturnValue({ doc: docMock });

      const req = { method: "POST", body: { code: "valid-code" }, headers: {} };
      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn(),
      };

      await lineAuth.lineAuthExchange(req, res);

      expect(deleteMock).toHaveBeenCalled();
      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith({
        customToken: "valid-custom-token",
        profile: { displayName: "LINE User", photoUrl: "https://example.com/photo.jpg", provider: "line" },
      });
    });
  });

  // --- cleanupExpiredLineAuthDocs ---
  describe("cleanupExpiredLineAuthDocs", () => {
    it("should delete expired states and tokens", async () => {
      const batchDeleteMock = jest.fn();
      const batchCommitMock = jest.fn().mockResolvedValue(undefined);
      db.batch = jest.fn().mockReturnValue({
        delete: batchDeleteMock,
        commit: batchCommitMock,
      });

      const statesDoc = { ref: { id: "state1" } };
      const tokensDoc = { ref: { id: "token1" } };

      const statesQuery = {
        where: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue({
            empty: false,
            size: 1,
            docs: [statesDoc],
          }),
        }),
      };

      const tokensQuery = {
        where: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue({
            empty: false,
            size: 1,
            docs: [tokensDoc],
          }),
        }),
      };

      db.collection.mockImplementation((name) => {
        if (name === "line_auth_states") return statesQuery;
        if (name === "line_auth_tokens") return tokensQuery;
        return statesQuery;
      });

      await lineAuth.cleanupExpiredLineAuthDocs();

      expect(batchDeleteMock).toHaveBeenCalledWith(statesDoc.ref);
      expect(batchDeleteMock).toHaveBeenCalledWith(tokensDoc.ref);
      expect(batchCommitMock).toHaveBeenCalledTimes(2);
    });

    it("should not commit batch when no expired docs found", async () => {
      const batchCommitMock = jest.fn().mockResolvedValue(undefined);
      db.batch = jest.fn().mockReturnValue({
        delete: jest.fn(),
        commit: batchCommitMock,
      });

      const emptyQuery = {
        where: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue({
            empty: true,
            size: 0,
            docs: [],
          }),
        }),
      };

      db.collection.mockReturnValue(emptyQuery);

      await lineAuth.cleanupExpiredLineAuthDocs();

      expect(batchCommitMock).not.toHaveBeenCalled();
    });
  });
});
