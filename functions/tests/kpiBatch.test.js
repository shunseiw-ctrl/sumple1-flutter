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
  firestoreFn.Timestamp = {
    fromDate: jest.fn((d) => ({ toDate: () => d, _seconds: Math.floor(d.getTime() / 1000) })),
  };

  return {
    initializeApp: jest.fn(),
    firestore: firestoreFn,
  };
});

jest.mock("firebase-functions/v2/scheduler", () => ({
  onSchedule: jest.fn((opts, handler) => handler),
}));

jest.mock("firebase-functions/logger", () => ({
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
}));

const kpiBatch = require("../src/kpiBatch");
const logger = require("firebase-functions/logger");

describe("kpiBatch", () => {
  let db;

  beforeEach(() => {
    jest.clearAllMocks();
    db = admin.firestore();
  });

  describe("dailyKpiAggregation", () => {
    it("should be a function", () => {
      expect(typeof kpiBatch.dailyKpiAggregation).toBe("function");
    });

    it("should aggregate daily KPI data and write to kpi_daily", async () => {
      const setMock = jest.fn().mockResolvedValue(undefined);
      const docMock = jest.fn().mockReturnValue({ set: setMock });

      // count() クエリのモック
      const countGetMock = jest.fn().mockResolvedValue({ data: () => ({ count: 5 }) });
      const countMock = jest.fn().mockReturnValue({ get: countGetMock });

      // earnings sum クエリのモック
      const earningsGetMock = jest.fn().mockResolvedValue({
        docs: [
          { data: () => ({ amount: 10000 }) },
          { data: () => ({ amount: 20000 }) },
        ],
      });

      const queryMock = {
        where: jest.fn().mockReturnThis(),
        count: countMock,
        get: earningsGetMock,
        select: jest.fn().mockReturnThis(),
      };

      db.collection.mockImplementation((name) => {
        if (name === "kpi_daily") return { doc: docMock };
        return queryMock;
      });

      await kpiBatch.dailyKpiAggregation();

      expect(db.collection).toHaveBeenCalledWith("kpi_daily");
      expect(setMock).toHaveBeenCalledWith(
        expect.objectContaining({
          newUsers: expect.any(Number),
          newJobs: expect.any(Number),
          newApplications: expect.any(Number),
          dailyEarnings: expect.any(Number),
          activeChats: expect.any(Number),
        }),
      );
      expect(logger.info).toHaveBeenCalledWith(
        "Daily KPI aggregation completed",
        expect.any(Object),
      );
    });

    it("should handle errors gracefully", async () => {
      db.collection.mockImplementation(() => {
        throw new Error("Firestore error");
      });

      await kpiBatch.dailyKpiAggregation();

      expect(logger.error).toHaveBeenCalledWith(
        "Daily KPI aggregation failed",
        expect.any(Error),
      );
    });
  });

  describe("monthlyKpiAggregation", () => {
    it("should be a function", () => {
      expect(typeof kpiBatch.monthlyKpiAggregation).toBe("function");
    });

    it("should aggregate monthly KPI data and write to kpi_monthly", async () => {
      const setMock = jest.fn().mockResolvedValue(undefined);
      const docMock = jest.fn().mockReturnValue({ set: setMock });

      const countGetMock = jest.fn().mockResolvedValue({ data: () => ({ count: 10 }) });
      const countMock = jest.fn().mockReturnValue({ get: countGetMock });

      const earningsGetMock = jest.fn().mockResolvedValue({
        docs: [
          { data: () => ({ amount: 50000 }) },
          { data: () => ({ amount: 30000 }) },
        ],
      });

      const appsGetMock = jest.fn().mockResolvedValue({
        docs: [
          { data: () => ({ jobId: "job1" }) },
          { data: () => ({ jobId: "job2" }) },
          { data: () => ({ jobId: "job1" }) },
        ],
      });

      const queryMock = {
        where: jest.fn().mockReturnThis(),
        count: countMock,
        get: earningsGetMock,
        select: jest.fn().mockReturnValue({
          get: appsGetMock,
          where: jest.fn().mockReturnThis(),
        }),
      };

      db.collection.mockImplementation((name) => {
        if (name === "kpi_monthly") return { doc: docMock };
        return queryMock;
      });

      await kpiBatch.monthlyKpiAggregation();

      expect(db.collection).toHaveBeenCalledWith("kpi_monthly");
      expect(setMock).toHaveBeenCalledWith(
        expect.objectContaining({
          mau: expect.any(Number),
          monthlyEarnings: expect.any(Number),
          jobFillRate: expect.any(Number),
          totalJobs: expect.any(Number),
          totalUsers: expect.any(Number),
          totalApplications: expect.any(Number),
        }),
      );
      expect(logger.info).toHaveBeenCalledWith(
        "Monthly KPI aggregation completed",
        expect.any(Object),
      );
    });

    it("should handle errors gracefully", async () => {
      db.collection.mockImplementation(() => {
        throw new Error("Firestore error");
      });

      await kpiBatch.monthlyKpiAggregation();

      expect(logger.error).toHaveBeenCalledWith(
        "Monthly KPI aggregation failed",
        expect.any(Error),
      );
    });

    it("should calculate jobFillRate as 0 when no jobs exist", async () => {
      const setMock = jest.fn().mockResolvedValue(undefined);
      const docMock = jest.fn().mockReturnValue({ set: setMock });

      // totalJobs = 0
      const countGetMock = jest.fn().mockResolvedValue({ data: () => ({ count: 0 }) });
      const countMock = jest.fn().mockReturnValue({ get: countGetMock });

      const earningsGetMock = jest.fn().mockResolvedValue({ docs: [] });
      const appsGetMock = jest.fn().mockResolvedValue({ docs: [] });

      const queryMock = {
        where: jest.fn().mockReturnThis(),
        count: countMock,
        get: earningsGetMock,
        select: jest.fn().mockReturnValue({
          get: appsGetMock,
          where: jest.fn().mockReturnThis(),
        }),
      };

      db.collection.mockImplementation((name) => {
        if (name === "kpi_monthly") return { doc: docMock };
        return queryMock;
      });

      await kpiBatch.monthlyKpiAggregation();

      expect(setMock).toHaveBeenCalledWith(
        expect.objectContaining({
          jobFillRate: 0,
        }),
      );
    });
  });
});
