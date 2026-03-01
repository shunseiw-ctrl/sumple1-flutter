const admin = require("firebase-admin");

// --- firebase-admin モック ---
jest.mock("firebase-admin", () => {
  const firestoreMock = {
    doc: jest.fn(),
    collection: jest.fn(),
  };
  const firestoreFn = jest.fn(() => firestoreMock);
  firestoreFn.FieldValue = {
    increment: jest.fn((n) => ({ __increment: n })),
    serverTimestamp: jest.fn(() => ({ __serverTimestamp: true })),
  };

  return {
    initializeApp: jest.fn(),
    firestore: firestoreFn,
  };
});

jest.mock("firebase-functions/v2/firestore", () => ({
  onDocumentCreated: jest.fn((opts, handler) => handler),
  onDocumentDeleted: jest.fn((opts, handler) => handler),
  onDocumentWritten: jest.fn((opts, handler) => handler),
}));

jest.mock("firebase-functions/v2/scheduler", () => ({
  onSchedule: jest.fn((opts, handler) => handler),
}));

jest.mock("firebase-functions/logger", () => ({
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
}));

const {
  incrementDistributed,
  getDistributedCount,
  initializeShards,
  syncDistributedCounters,
  NUM_SHARDS,
} = require("../src/distributedCounter");

describe("distributedCounter", () => {
  let db;

  beforeEach(() => {
    jest.clearAllMocks();
    db = admin.firestore();
  });

  describe("NUM_SHARDS", () => {
    it("should be 10", () => {
      expect(NUM_SHARDS).toBe(10);
    });
  });

  describe("incrementDistributed", () => {
    it("should write to a random shard", async () => {
      const setMock = jest.fn().mockResolvedValue(undefined);
      const shardDocMock = jest.fn().mockReturnValue({ set: setMock });
      const shardsCollMock = jest.fn().mockReturnValue({ doc: shardDocMock });
      const counterDocMock = jest.fn().mockReturnValue({ collection: shardsCollMock });
      const counterCollMock = { doc: counterDocMock };

      db.collection.mockReturnValue(counterCollMock);

      await incrementDistributed("stats", "totalJobs", 1);

      expect(db.collection).toHaveBeenCalledWith("counters");
      expect(counterDocMock).toHaveBeenCalledWith("stats");
      expect(shardsCollMock).toHaveBeenCalledWith("shards");
      // shardId is random 0-9
      expect(shardDocMock).toHaveBeenCalledWith(expect.stringMatching(/^[0-9]$/));
      expect(setMock).toHaveBeenCalledWith(
        expect.objectContaining({
          totalJobs: { __increment: 1 },
        }),
        { merge: true },
      );
    });

    it("should handle negative delta", async () => {
      const setMock = jest.fn().mockResolvedValue(undefined);
      const shardDocMock = jest.fn().mockReturnValue({ set: setMock });
      const shardsCollMock = jest.fn().mockReturnValue({ doc: shardDocMock });
      const counterDocMock = jest.fn().mockReturnValue({ collection: shardsCollMock });

      db.collection.mockReturnValue({ doc: counterDocMock });

      await incrementDistributed("stats", "totalJobs", -1);

      expect(setMock).toHaveBeenCalledWith(
        expect.objectContaining({
          totalJobs: { __increment: -1 },
        }),
        { merge: true },
      );
    });
  });

  describe("getDistributedCount", () => {
    it("should sum all shards", async () => {
      const shardsSnap = {
        docs: [
          { data: () => ({ totalJobs: 3 }) },
          { data: () => ({ totalJobs: 7 }) },
          { data: () => ({ totalJobs: 5 }) },
        ],
      };

      const getMock = jest.fn().mockResolvedValue(shardsSnap);
      const shardsCollMock = jest.fn().mockReturnValue({ get: getMock });
      const counterDocMock = jest.fn().mockReturnValue({ collection: shardsCollMock });

      db.collection.mockReturnValue({ doc: counterDocMock });

      const count = await getDistributedCount("stats", "totalJobs");

      expect(count).toBe(15);
    });

    it("should return 0 when no shards exist", async () => {
      const shardsSnap = { docs: [] };
      const getMock = jest.fn().mockResolvedValue(shardsSnap);
      const shardsCollMock = jest.fn().mockReturnValue({ get: getMock });
      const counterDocMock = jest.fn().mockReturnValue({ collection: shardsCollMock });

      db.collection.mockReturnValue({ doc: counterDocMock });

      const count = await getDistributedCount("stats", "totalJobs");

      expect(count).toBe(0);
    });

    it("should ignore non-numeric values", async () => {
      const shardsSnap = {
        docs: [
          { data: () => ({ totalJobs: 3 }) },
          { data: () => ({ totalJobs: "invalid" }) },
          { data: () => ({ otherField: 99 }) },
        ],
      };

      const getMock = jest.fn().mockResolvedValue(shardsSnap);
      const shardsCollMock = jest.fn().mockReturnValue({ get: getMock });
      const counterDocMock = jest.fn().mockReturnValue({ collection: shardsCollMock });

      db.collection.mockReturnValue({ doc: counterDocMock });

      const count = await getDistributedCount("stats", "totalJobs");

      expect(count).toBe(3);
    });
  });

  describe("initializeShards", () => {
    it("should create NUM_SHARDS documents", async () => {
      const batchSetMock = jest.fn();
      const batchCommitMock = jest.fn().mockResolvedValue(undefined);
      db.batch = jest.fn().mockReturnValue({
        set: batchSetMock,
        commit: batchCommitMock,
      });

      const shardDocMock = jest.fn().mockReturnValue({ id: "shard" });
      const shardsCollMock = jest.fn().mockReturnValue({ doc: shardDocMock });
      const counterDocMock = jest.fn().mockReturnValue({ collection: shardsCollMock });

      db.collection.mockReturnValue({ doc: counterDocMock });

      await initializeShards("stats", { totalJobs: 0, totalUsers: 0 });

      expect(batchSetMock).toHaveBeenCalledTimes(NUM_SHARDS);
      expect(batchCommitMock).toHaveBeenCalledTimes(1);
    });
  });

  describe("syncDistributedCounters", () => {
    it("should sync shard totals to stats/realtime", async () => {
      const setMock = jest.fn().mockResolvedValue(undefined);
      const statDocMock = { set: setMock };

      const shardsSnap = {
        docs: [
          { data: () => ({ totalJobs: 5, totalApplications: 3, pendingApplications: 1, totalUsers: 10 }) },
          { data: () => ({ totalJobs: 3, totalApplications: 2, pendingApplications: 0, totalUsers: 5 }) },
        ],
      };

      const getMock = jest.fn().mockResolvedValue(shardsSnap);
      const shardsCollMock = jest.fn().mockReturnValue({ get: getMock });
      const counterDocMock = jest.fn().mockReturnValue({ collection: shardsCollMock });

      db.collection.mockReturnValue({ doc: counterDocMock });
      db.doc.mockReturnValue(statDocMock);

      await syncDistributedCounters();

      expect(setMock).toHaveBeenCalledWith(
        expect.objectContaining({
          totalJobs: 8,
          totalApplications: 5,
          pendingApplications: 1,
          totalUsers: 15,
        }),
        { merge: true },
      );
    });
  });
});
