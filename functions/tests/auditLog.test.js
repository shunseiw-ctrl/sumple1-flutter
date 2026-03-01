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

const {
  writeAuditLog,
  onAuditJobWrite,
  onAuditApplicationWrite,
  onAuditPaymentCreated,
  onAuditRatingCreated,
} = require("../src/auditLog");

describe("writeAuditLog", () => {
  let db;
  let auditAdd;

  beforeEach(() => {
    jest.clearAllMocks();
    db = admin.firestore();
    auditAdd = jest.fn().mockResolvedValue({ id: "log-1" });
    db.collection.mockReturnValue({ add: auditAdd });
  });

  test("正しい構造で audit_log を書き込む", async () => {
    await writeAuditLog("test_action", "user-1", "jobs", "job-1", {
      key: "value",
    });

    expect(db.collection).toHaveBeenCalledWith("audit_logs");
    expect(auditAdd).toHaveBeenCalledWith({
      action: "test_action",
      actorUid: "user-1",
      targetCollection: "jobs",
      targetDocId: "job-1",
      details: { key: "value" },
      timestamp: "SERVER_TIMESTAMP",
    });
  });

  test("details が空の場合も正常に動作する", async () => {
    await writeAuditLog("test_action", "user-1", "jobs", "job-1");

    expect(auditAdd).toHaveBeenCalledWith(
      expect.objectContaining({
        details: {},
      }),
    );
  });
});

describe("onAuditJobWrite", () => {
  let db;
  let auditAdd;

  beforeEach(() => {
    jest.clearAllMocks();
    db = admin.firestore();
    auditAdd = jest.fn().mockResolvedValue({ id: "log-1" });
    db.collection.mockReturnValue({ add: auditAdd });
  });

  test("job 作成時に job_created をログする", async () => {
    const event = {
      params: { jobId: "job-123" },
      data: {
        before: { data: () => undefined },
        after: {
          data: () => ({
            ownerId: "owner-1",
            title: "Test Job",
          }),
        },
      },
    };

    await onAuditJobWrite.run(event);

    expect(auditAdd).toHaveBeenCalledWith(
      expect.objectContaining({
        action: "job_created",
        actorUid: "owner-1",
        targetCollection: "jobs",
        targetDocId: "job-123",
      }),
    );
  });

  test("job 更新時に job_updated をログする", async () => {
    const event = {
      params: { jobId: "job-123" },
      data: {
        before: {
          data: () => ({ ownerId: "owner-1", title: "Old Title" }),
        },
        after: {
          data: () => ({ ownerId: "owner-1", title: "New Title" }),
        },
      },
    };

    await onAuditJobWrite.run(event);

    expect(auditAdd).toHaveBeenCalledWith(
      expect.objectContaining({
        action: "job_updated",
        actorUid: "owner-1",
        targetCollection: "jobs",
        targetDocId: "job-123",
      }),
    );
  });

  test("job 削除時に job_deleted をログする", async () => {
    const event = {
      params: { jobId: "job-123" },
      data: {
        before: {
          data: () => ({ ownerId: "owner-1", title: "Deleted Job" }),
        },
        after: { data: () => undefined },
      },
    };

    await onAuditJobWrite.run(event);

    expect(auditAdd).toHaveBeenCalledWith(
      expect.objectContaining({
        action: "job_deleted",
        actorUid: "owner-1",
        targetCollection: "jobs",
        targetDocId: "job-123",
      }),
    );
  });
});

describe("onAuditApplicationWrite", () => {
  let db;
  let auditAdd;

  beforeEach(() => {
    jest.clearAllMocks();
    db = admin.firestore();
    auditAdd = jest.fn().mockResolvedValue({ id: "log-1" });
    db.collection.mockReturnValue({ add: auditAdd });
  });

  test("application 作成時に application_created をログする", async () => {
    const event = {
      params: { appId: "app-123" },
      data: {
        before: { data: () => undefined },
        after: {
          data: () => ({
            applicantUid: "applicant-1",
            status: "applied",
            jobId: "job-1",
          }),
        },
      },
    };

    await onAuditApplicationWrite.run(event);

    expect(auditAdd).toHaveBeenCalledWith(
      expect.objectContaining({
        action: "application_created",
        actorUid: "applicant-1",
        targetCollection: "applications",
        targetDocId: "app-123",
      }),
    );
  });

  test("ステータス変更時に application_status_changed をログする", async () => {
    const event = {
      params: { appId: "app-123" },
      data: {
        before: {
          data: () => ({
            applicantUid: "applicant-1",
            adminUid: "admin-1",
            status: "applied",
            jobId: "job-1",
          }),
        },
        after: {
          data: () => ({
            applicantUid: "applicant-1",
            adminUid: "admin-1",
            status: "accepted",
            jobId: "job-1",
          }),
        },
      },
    };

    await onAuditApplicationWrite.run(event);

    expect(auditAdd).toHaveBeenCalledWith(
      expect.objectContaining({
        action: "application_status_changed",
        details: expect.objectContaining({
          fromStatus: "applied",
          toStatus: "accepted",
        }),
      }),
    );
  });
});

describe("onAuditPaymentCreated", () => {
  let db;
  let auditAdd;

  beforeEach(() => {
    jest.clearAllMocks();
    db = admin.firestore();
    auditAdd = jest.fn().mockResolvedValue({ id: "log-1" });
    db.collection.mockReturnValue({ add: auditAdd });
  });

  test("payment 作成時に payment_created をログする", async () => {
    const event = {
      params: { paymentId: "pay-123" },
      data: {
        data: () => ({
          adminUid: "admin-1",
          workerUid: "worker-1",
          amount: 50000,
        }),
      },
    };

    await onAuditPaymentCreated.run(event);

    expect(auditAdd).toHaveBeenCalledWith(
      expect.objectContaining({
        action: "payment_created",
        actorUid: "admin-1",
        targetCollection: "payments",
        targetDocId: "pay-123",
        details: expect.objectContaining({
          amount: 50000,
          workerUid: "worker-1",
        }),
      }),
    );
  });
});

describe("onAuditRatingCreated", () => {
  let db;
  let auditAdd;

  beforeEach(() => {
    jest.clearAllMocks();
    db = admin.firestore();
    auditAdd = jest.fn().mockResolvedValue({ id: "log-1" });
    db.collection.mockReturnValue({ add: auditAdd });
  });

  test("rating 作成時に rating_created をログする", async () => {
    const event = {
      params: { ratingId: "rating-123" },
      data: {
        data: () => ({
          raterUid: "admin-1",
          targetUid: "worker-1",
          stars: 5,
        }),
      },
    };

    await onAuditRatingCreated.run(event);

    expect(auditAdd).toHaveBeenCalledWith(
      expect.objectContaining({
        action: "rating_created",
        actorUid: "admin-1",
        targetCollection: "ratings",
        targetDocId: "rating-123",
        details: expect.objectContaining({
          targetUid: "worker-1",
          stars: 5,
        }),
      }),
    );
  });
});
