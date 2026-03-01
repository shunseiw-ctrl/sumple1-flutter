const admin = require("firebase-admin");
const { describe, it, expect, beforeEach, jest: jestObj } = require("@jest/globals");

// --- firebase-admin モック ---
jest.mock("firebase-admin", () => {
  const firestoreMock = {
    doc: jest.fn(),
    collection: jest.fn(),
  };
  const firestoreFn = jest.fn(() => firestoreMock);
  // admin.firestore.FieldValue (static property on function)
  firestoreFn.FieldValue = {
    increment: jest.fn((n) => ({ __increment: n })),
    serverTimestamp: jest.fn(() => ({ __serverTimestamp: true })),
  };
  return {
    initializeApp: jest.fn(),
    firestore: firestoreFn,
  };
});

// firebase-functions v2 モック
jest.mock("firebase-functions/v2/firestore", () => ({
  onDocumentCreated: jest.fn((opts, handler) => handler),
  onDocumentDeleted: jest.fn((opts, handler) => handler),
  onDocumentWritten: jest.fn((opts, handler) => handler),
}));

jest.mock("firebase-functions/v2/https", () => ({
  onCall: jest.fn((opts, handler) => handler),
  HttpsError: class HttpsError extends Error {
    constructor(code, message) {
      super(message);
      this.code = code;
    }
  },
}));

jest.mock("firebase-functions/logger", () => ({
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
}));

const counters = require("../src/counters");
const initCounters = require("../src/initCounters");

describe("counters", () => {
  let db;
  let docRef;

  beforeEach(() => {
    jest.clearAllMocks();
    db = admin.firestore();
    docRef = {
      update: jest.fn().mockResolvedValue(undefined),
      set: jest.fn().mockResolvedValue(undefined),
    };
    db.doc.mockReturnValue(docRef);
  });

  describe("onJobCreated", () => {
    it("should increment totalJobs by 1", async () => {
      await counters.onJobCreated({ params: { jobId: "job1" }, data: {} });

      expect(db.doc).toHaveBeenCalledWith("stats/realtime");
      expect(docRef.update).toHaveBeenCalledWith(
        expect.objectContaining({
          totalJobs: { __increment: 1 },
        }),
      );
    });
  });

  describe("onJobDeleted", () => {
    it("should decrement totalJobs by 1", async () => {
      await counters.onJobDeleted({ params: { jobId: "job1" }, data: {} });

      expect(docRef.update).toHaveBeenCalledWith(
        expect.objectContaining({
          totalJobs: { __increment: -1 },
        }),
      );
    });
  });

  describe("onApplicationCreated", () => {
    it("should increment totalApplications and pendingApplications for applied status", async () => {
      const event = {
        params: { appId: "app1" },
        data: { data: () => ({ status: "applied" }) },
      };

      await counters.onApplicationCreated(event);

      expect(docRef.update).toHaveBeenCalledWith(
        expect.objectContaining({
          totalApplications: { __increment: 1 },
          pendingApplications: { __increment: 1 },
        }),
      );
    });

    it("should increment only totalApplications for non-applied status", async () => {
      const event = {
        params: { appId: "app1" },
        data: { data: () => ({ status: "assigned" }) },
      };

      await counters.onApplicationCreated(event);

      const updateCall = docRef.update.mock.calls[0][0];
      expect(updateCall.totalApplications).toEqual({ __increment: 1 });
      expect(updateCall.pendingApplications).toBeUndefined();
    });
  });

  describe("onApplicationUpdated", () => {
    it("should decrement pendingApplications when status changes from applied to accepted", async () => {
      const event = {
        params: { appId: "app1" },
        data: {
          before: { data: () => ({ status: "applied" }) },
          after: { data: () => ({ status: "assigned" }) },
        },
      };

      await counters.onApplicationUpdated(event);

      expect(docRef.update).toHaveBeenCalledWith(
        expect.objectContaining({
          pendingApplications: { __increment: -1 },
        }),
      );
    });

    it("should increment pendingApplications when status changes back to applied", async () => {
      const event = {
        params: { appId: "app1" },
        data: {
          before: { data: () => ({ status: "assigned" }) },
          after: { data: () => ({ status: "applied" }) },
        },
      };

      await counters.onApplicationUpdated(event);

      expect(docRef.update).toHaveBeenCalledWith(
        expect.objectContaining({
          pendingApplications: { __increment: 1 },
        }),
      );
    });

    it("should not update when status does not change", async () => {
      const event = {
        params: { appId: "app1" },
        data: {
          before: { data: () => ({ status: "assigned" }) },
          after: { data: () => ({ status: "assigned" }) },
        },
      };

      await counters.onApplicationUpdated(event);

      expect(docRef.update).not.toHaveBeenCalled();
    });

    it("should not update when before data is missing (create event)", async () => {
      const event = {
        params: { appId: "app1" },
        data: {
          before: { data: () => null },
          after: { data: () => ({ status: "applied" }) },
        },
      };

      await counters.onApplicationUpdated(event);

      expect(docRef.update).not.toHaveBeenCalled();
    });

    it("should not update when non-applied status changes to another non-applied status", async () => {
      const event = {
        params: { appId: "app1" },
        data: {
          before: { data: () => ({ status: "assigned" }) },
          after: { data: () => ({ status: "in_progress" }) },
        },
      };

      await counters.onApplicationUpdated(event);

      expect(docRef.update).not.toHaveBeenCalled();
    });
  });

  describe("onProfileCreated", () => {
    it("should increment totalUsers by 1", async () => {
      await counters.onProfileCreated({ params: { uid: "user1" }, data: {} });

      expect(docRef.update).toHaveBeenCalledWith(
        expect.objectContaining({
          totalUsers: { __increment: 1 },
        }),
      );
    });
  });

  describe("stats/realtime initialization on not-found", () => {
    it("should create stats document when it does not exist", async () => {
      const notFoundError = new Error("not found");
      notFoundError.code = 5;
      docRef.update.mockRejectedValueOnce(notFoundError);

      await counters.onJobCreated({ params: { jobId: "job1" }, data: {} });

      expect(docRef.set).toHaveBeenCalledWith(
        expect.objectContaining({
          totalJobs: 1,
          totalApplications: 0,
          pendingApplications: 0,
          totalUsers: 0,
        }),
      );
    });

    it("should create stats document with code string not-found", async () => {
      const notFoundError = new Error("not found");
      notFoundError.code = "not-found";
      docRef.update.mockRejectedValueOnce(notFoundError);

      await counters.onProfileCreated({ params: { uid: "user1" }, data: {} });

      expect(docRef.set).toHaveBeenCalledWith(
        expect.objectContaining({
          totalUsers: 1,
          totalJobs: 0,
          totalApplications: 0,
          pendingApplications: 0,
        }),
      );
    });
  });
});

describe("initializeCounters", () => {
  let db;

  beforeEach(() => {
    jest.clearAllMocks();
    db = admin.firestore();
  });

  it("should throw unauthenticated when no auth", async () => {
    await expect(
      initCounters.initializeCounters({ auth: null, data: {} }),
    ).rejects.toThrow("ログインが必要です");
  });

  it("should throw permission-denied when not admin", async () => {
    const adminDocRef = {
      get: jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({ adminUids: ["other-uid"], emails: [] }),
      }),
    };
    db.doc.mockReturnValue(adminDocRef);

    await expect(
      initCounters.initializeCounters({
        auth: { uid: "user1", token: { email: "user@example.com" } },
        data: {},
      }),
    ).rejects.toThrow("管理者権限が必要です");
  });
});
