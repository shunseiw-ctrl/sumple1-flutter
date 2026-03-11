const admin = require("firebase-admin");
const { createMockFirestoreEvent } = require("./helpers/setup");

// firebase-admin をモック（Object.assign パターンで FieldValue を含める）
jest.mock("firebase-admin", () => {
  const firestoreMock = {
    collection: jest.fn(),
    collectionGroup: jest.fn(),
    doc: jest.fn(),
    batch: jest.fn(),
  };
  const messagingMock = {
    send: jest.fn().mockResolvedValue("message-id-123"),
  };
  return {
    initializeApp: jest.fn(),
    firestore: Object.assign(jest.fn(() => firestoreMock), {
      FieldValue: {
        serverTimestamp: jest.fn().mockReturnValue("SERVER_TIMESTAMP"),
      },
    }),
    messaging: jest.fn(() => messagingMock),
  };
});

// firebase-functions/v2/firestore をモック
jest.mock("firebase-functions/v2/firestore", () => ({
  onDocumentCreated: jest.fn((opts, handler) => handler),
}));

// firebase-functions/v2/scheduler をモック
jest.mock("firebase-functions/v2/scheduler", () => ({
  onSchedule: jest.fn((opts, handler) => handler),
}));

// firebase-functions/logger をモック
jest.mock("firebase-functions/logger", () => ({
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
}));

const logger = require("firebase-functions/logger");

// ========================================================
// getAdminUids ヘルパーのロジック
// ========================================================
describe("getAdminUids ヘルパー", () => {
  let firestoreMock;

  beforeEach(() => {
    jest.clearAllMocks();
    firestoreMock = admin.firestore();
  });

  // ソースコードの getAdminUids ロジックを再現
  async function getAdminUids() {
    const doc = await firestoreMock.doc("config/admins").get();
    if (!doc.exists) return [];
    return doc.data().adminUids || [];
  }

  test("config/admins ドキュメントから管理者UIDリストを返す", async () => {
    const mockDoc = {
      exists: true,
      data: () => ({ adminUids: ["admin-1", "admin-2"] }),
    };
    firestoreMock.doc.mockReturnValue({
      get: jest.fn().mockResolvedValue(mockDoc),
    });

    const result = await getAdminUids();
    expect(result).toEqual(["admin-1", "admin-2"]);
    expect(firestoreMock.doc).toHaveBeenCalledWith("config/admins");
  });

  test("ドキュメントが存在しない場合は空配列を返す", async () => {
    const mockDoc = {
      exists: false,
      data: () => null,
    };
    firestoreMock.doc.mockReturnValue({
      get: jest.fn().mockResolvedValue(mockDoc),
    });

    const result = await getAdminUids();
    expect(result).toEqual([]);
  });

  test("adminUids フィールドが未定義の場合は空配列を返す", async () => {
    const mockDoc = {
      exists: true,
      data: () => ({}),
    };
    firestoreMock.doc.mockReturnValue({
      get: jest.fn().mockResolvedValue(mockDoc),
    });

    const result = await getAdminUids();
    expect(result).toEqual([]);
  });
});

// ========================================================
// notifyAdmins ヘルパーのロジック
// ========================================================
describe("notifyAdmins ヘルパー", () => {
  let firestoreMock;

  beforeEach(() => {
    jest.clearAllMocks();
    firestoreMock = admin.firestore();
  });

  // getAdminUids + notifyAdmins のロジックを再現
  async function getAdminUids() {
    const doc = await firestoreMock.doc("config/admins").get();
    if (!doc.exists) return [];
    return doc.data().adminUids || [];
  }

  async function notifyAdmins(title, body, type, data = {}) {
    const adminUids = await getAdminUids();
    const batch = firestoreMock.batch();
    for (const uid of adminUids) {
      const ref = firestoreMock.collection("notifications").doc();
      batch.set(ref, {
        targetUid: uid,
        title,
        body,
        type,
        data,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    logger.info(`Notified ${adminUids.length} admins`, { type });
  }

  test("全管理者に対してバッチで通知ドキュメントを作成する", async () => {
    // getAdminUids のモック
    const mockAdminsDoc = {
      exists: true,
      data: () => ({ adminUids: ["admin-1", "admin-2"] }),
    };
    firestoreMock.doc.mockReturnValue({
      get: jest.fn().mockResolvedValue(mockAdminsDoc),
    });

    // batch のモック
    const mockBatch = {
      set: jest.fn(),
      commit: jest.fn().mockResolvedValue(undefined),
    };
    firestoreMock.batch.mockReturnValue(mockBatch);

    // collection("notifications").doc() のモック
    const mockNotifRef = { id: "new-notif-doc" };
    firestoreMock.collection.mockReturnValue({
      doc: jest.fn().mockReturnValue(mockNotifRef),
    });

    await notifyAdmins("テストタイトル", "テスト本文", "test_type", { key: "val" });

    // 管理者2人分の batch.set が呼ばれる
    expect(mockBatch.set).toHaveBeenCalledTimes(2);

    // 1人目の通知内容を検証
    expect(mockBatch.set).toHaveBeenCalledWith(
      mockNotifRef,
      expect.objectContaining({
        targetUid: "admin-1",
        title: "テストタイトル",
        body: "テスト本文",
        type: "test_type",
        data: { key: "val" },
        read: false,
        createdAt: "SERVER_TIMESTAMP",
      }),
    );

    // 2人目の通知内容を検証
    expect(mockBatch.set).toHaveBeenCalledWith(
      mockNotifRef,
      expect.objectContaining({
        targetUid: "admin-2",
      }),
    );

    // バッチがコミットされる
    expect(mockBatch.commit).toHaveBeenCalledTimes(1);

    // ログ出力を検証
    expect(logger.info).toHaveBeenCalledWith(
      "Notified 2 admins",
      { type: "test_type" },
    );
  });

  test("serverTimestamp が正しくセットされる", async () => {
    const mockAdminsDoc = {
      exists: true,
      data: () => ({ adminUids: ["admin-1"] }),
    };
    firestoreMock.doc.mockReturnValue({
      get: jest.fn().mockResolvedValue(mockAdminsDoc),
    });

    const mockBatch = {
      set: jest.fn(),
      commit: jest.fn().mockResolvedValue(undefined),
    };
    firestoreMock.batch.mockReturnValue(mockBatch);

    const mockNotifRef = { id: "new-notif" };
    firestoreMock.collection.mockReturnValue({
      doc: jest.fn().mockReturnValue(mockNotifRef),
    });

    await notifyAdmins("タイトル", "本文", "type1");

    // createdAt に SERVER_TIMESTAMP がセットされていることを確認
    expect(mockBatch.set).toHaveBeenCalledWith(
      mockNotifRef,
      expect.objectContaining({
        createdAt: "SERVER_TIMESTAMP",
      }),
    );
    expect(admin.firestore.FieldValue.serverTimestamp).toHaveBeenCalled();
  });
});

// ========================================================
// onApplicationCreatedNotify のロジック
// ========================================================
describe("onApplicationCreatedNotify", () => {
  let firestoreMock;

  beforeEach(() => {
    jest.clearAllMocks();
    firestoreMock = admin.firestore();
  });

  // getAdminUids + notifyAdmins + ハンドラロジックを再現
  async function getAdminUids() {
    const doc = await firestoreMock.doc("config/admins").get();
    if (!doc.exists) return [];
    return doc.data().adminUids || [];
  }

  async function notifyAdmins(title, body, type, data = {}) {
    const adminUids = await getAdminUids();
    const batch = firestoreMock.batch();
    for (const uid of adminUids) {
      const ref = firestoreMock.collection("notifications").doc();
      batch.set(ref, {
        targetUid: uid,
        title,
        body,
        type,
        data,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    logger.info(`Notified ${adminUids.length} admins`, { type });
  }

  async function handleApplicationCreated(event) {
    try {
      const snap = event.data;
      if (!snap) return;
      const data = snap.data() || {};
      const jobTitle = data.jobTitleSnapshot || data.projectNameSnapshot || "案件";
      const workerName = data.workerNameSnapshot || "ワーカー";
      await notifyAdmins(
        "新規応募",
        `${workerName}が「${jobTitle}」に応募しました`,
        "new_application",
        { applicationId: event.params.appId, jobId: data.jobId || "" },
      );
    } catch (e) {
      logger.error("onApplicationCreatedNotify failed", e);
    }
  }

  // テスト共通のモックセットアップ
  function setupAdminMocks(adminUids = ["admin-1"]) {
    const mockAdminsDoc = {
      exists: true,
      data: () => ({ adminUids }),
    };
    firestoreMock.doc.mockReturnValue({
      get: jest.fn().mockResolvedValue(mockAdminsDoc),
    });

    const mockBatch = {
      set: jest.fn(),
      commit: jest.fn().mockResolvedValue(undefined),
    };
    firestoreMock.batch.mockReturnValue(mockBatch);

    const mockNotifRef = { id: "notif-doc" };
    firestoreMock.collection.mockReturnValue({
      doc: jest.fn().mockReturnValue(mockNotifRef),
    });

    return { mockBatch, mockNotifRef };
  }

  test("スナップショットがnullの場合はスキップ", async () => {
    const event = { data: null, params: { appId: "app-1" } };
    await handleApplicationCreated(event);

    // notifyAdmins が呼ばれない（batch等のモックが使われない）
    expect(firestoreMock.batch).not.toHaveBeenCalled();
  });

  test("新規応募時に管理者に正しいタイトル・本文で通知する", async () => {
    const { mockBatch } = setupAdminMocks(["admin-1", "admin-2"]);

    const event = createMockFirestoreEvent(
      {
        jobTitleSnapshot: "内装工事A",
        workerNameSnapshot: "田中太郎",
        jobId: "job-001",
      },
      { appId: "app-123" },
    );

    await handleApplicationCreated(event);

    // 管理者2人分の通知が作成される
    expect(mockBatch.set).toHaveBeenCalledTimes(2);
    expect(mockBatch.set).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({
        title: "新規応募",
        body: "田中太郎が「内装工事A」に応募しました",
        type: "new_application",
        data: { applicationId: "app-123", jobId: "job-001" },
      }),
    );
    expect(mockBatch.commit).toHaveBeenCalled();
  });

  test("jobTitleSnapshot がない場合は projectNameSnapshot をフォールバック", async () => {
    const { mockBatch } = setupAdminMocks(["admin-1"]);

    const event = createMockFirestoreEvent(
      {
        projectNameSnapshot: "ビルB改修",
        workerNameSnapshot: "鈴木一郎",
      },
      { appId: "app-456" },
    );

    await handleApplicationCreated(event);

    expect(mockBatch.set).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({
        body: "鈴木一郎が「ビルB改修」に応募しました",
      }),
    );
  });

  test("名前・案件名が未設定の場合はデフォルト値を使う", async () => {
    const { mockBatch } = setupAdminMocks(["admin-1"]);

    const event = createMockFirestoreEvent(
      { jobId: "job-999" },
      { appId: "app-789" },
    );

    await handleApplicationCreated(event);

    expect(mockBatch.set).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({
        body: "ワーカーが「案件」に応募しました",
      }),
    );
  });
});

// ========================================================
// onWorkReportCreatedNotify のロジック
// ========================================================
describe("onWorkReportCreatedNotify", () => {
  let firestoreMock;

  beforeEach(() => {
    jest.clearAllMocks();
    firestoreMock = admin.firestore();
  });

  async function getAdminUids() {
    const doc = await firestoreMock.doc("config/admins").get();
    if (!doc.exists) return [];
    return doc.data().adminUids || [];
  }

  async function notifyAdmins(title, body, type, data = {}) {
    const adminUids = await getAdminUids();
    const batch = firestoreMock.batch();
    for (const uid of adminUids) {
      const ref = firestoreMock.collection("notifications").doc();
      batch.set(ref, {
        targetUid: uid,
        title,
        body,
        type,
        data,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    logger.info(`Notified ${adminUids.length} admins`, { type });
  }

  async function handleWorkReportCreated(event) {
    try {
      const snap = event.data;
      if (!snap) return;
      const data = snap.data() || {};
      const reportDate = data.reportDate || "";
      await notifyAdmins(
        "日報提出",
        `${reportDate}の日報が提出されました`,
        "work_report",
        { applicationId: event.params.appId, reportId: event.params.reportId },
      );
    } catch (e) {
      logger.error("onWorkReportCreatedNotify failed", e);
    }
  }

  function setupAdminMocks(adminUids = ["admin-1"]) {
    const mockAdminsDoc = {
      exists: true,
      data: () => ({ adminUids }),
    };
    firestoreMock.doc.mockReturnValue({
      get: jest.fn().mockResolvedValue(mockAdminsDoc),
    });

    const mockBatch = {
      set: jest.fn(),
      commit: jest.fn().mockResolvedValue(undefined),
    };
    firestoreMock.batch.mockReturnValue(mockBatch);

    const mockNotifRef = { id: "notif-doc" };
    firestoreMock.collection.mockReturnValue({
      doc: jest.fn().mockReturnValue(mockNotifRef),
    });

    return { mockBatch };
  }

  test("スナップショットがnullの場合はスキップ", async () => {
    const event = { data: null, params: { appId: "app-1", reportId: "r-1" } };
    await handleWorkReportCreated(event);
    expect(firestoreMock.batch).not.toHaveBeenCalled();
  });

  test("日報提出時に報告日付を含む通知を送る", async () => {
    const { mockBatch } = setupAdminMocks(["admin-1"]);

    const event = createMockFirestoreEvent(
      { reportDate: "2026-03-10" },
      { appId: "app-100", reportId: "report-200" },
    );

    await handleWorkReportCreated(event);

    expect(mockBatch.set).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({
        title: "日報提出",
        body: "2026-03-10の日報が提出されました",
        type: "work_report",
        data: { applicationId: "app-100", reportId: "report-200" },
      }),
    );
    expect(mockBatch.commit).toHaveBeenCalled();
  });

  test("reportDate が空の場合もエラーにならず通知する", async () => {
    const { mockBatch } = setupAdminMocks(["admin-1"]);

    const event = createMockFirestoreEvent(
      {},
      { appId: "app-100", reportId: "report-200" },
    );

    await handleWorkReportCreated(event);

    expect(mockBatch.set).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({
        body: "の日報が提出されました",
      }),
    );
  });
});

// ========================================================
// onInspectionCreatedNotify のロジック
// ========================================================
describe("onInspectionCreatedNotify", () => {
  let firestoreMock;

  beforeEach(() => {
    jest.clearAllMocks();
    firestoreMock = admin.firestore();
  });

  async function getAdminUids() {
    const doc = await firestoreMock.doc("config/admins").get();
    if (!doc.exists) return [];
    return doc.data().adminUids || [];
  }

  async function notifyAdmins(title, body, type, data = {}) {
    const adminUids = await getAdminUids();
    const batch = firestoreMock.batch();
    for (const uid of adminUids) {
      const ref = firestoreMock.collection("notifications").doc();
      batch.set(ref, {
        targetUid: uid,
        title,
        body,
        type,
        data,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    logger.info(`Notified ${adminUids.length} admins`, { type });
  }

  async function handleInspectionCreated(event) {
    try {
      const snap = event.data;
      if (!snap) return;
      const data = snap.data() || {};
      const result = data.result || "unknown";

      if (result === "failed" || result === "partial") {
        // 管理者に通知
        await notifyAdmins(
          "検査不合格",
          `検査結果: ${result === "failed" ? "不合格" : "一部不合格"}`,
          "inspection_failed",
          { applicationId: event.params.appId, inspectionId: event.params.inspectionId },
        );

        // ワーカーにも通知
        const appDoc = await firestoreMock.doc(`applications/${event.params.appId}`).get();
        if (appDoc.exists) {
          const appData = appDoc.data() || {};
          const workerUid = appData.applicantUid;
          if (workerUid) {
            await firestoreMock.collection("notifications").add({
              targetUid: workerUid,
              title: "検査結果",
              body: result === "failed" ? "検査が不合格でした。修正をお願いします。" : "検査で一部不合格の項目があります。",
              type: "inspection_result",
              data: { applicationId: event.params.appId },
              read: false,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          }
        }
      }
    } catch (e) {
      logger.error("onInspectionCreatedNotify failed", e);
    }
  }

  // doc() の呼び出しパスに応じて異なるモックを返すヘルパー
  function setupMocks({ adminUids = ["admin-1"], appData = null } = {}) {
    // doc() のモック: パスに応じて返すドキュメントを変える
    firestoreMock.doc.mockImplementation((path) => {
      if (path === "config/admins") {
        return {
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({ adminUids }),
          }),
        };
      }
      if (path && path.startsWith("applications/")) {
        return {
          get: jest.fn().mockResolvedValue(
            appData
              ? { exists: true, data: () => appData }
              : { exists: false, data: () => null },
          ),
        };
      }
      return {
        get: jest.fn().mockResolvedValue({ exists: false, data: () => null }),
      };
    });

    const mockBatch = {
      set: jest.fn(),
      commit: jest.fn().mockResolvedValue(undefined),
    };
    firestoreMock.batch.mockReturnValue(mockBatch);

    // collection("notifications") のモック: doc() と add() を両方対応
    const mockNotifRef = { id: "notif-doc" };
    const mockAdd = jest.fn().mockResolvedValue({ id: "added-notif" });
    firestoreMock.collection.mockReturnValue({
      doc: jest.fn().mockReturnValue(mockNotifRef),
      add: mockAdd,
    });

    return { mockBatch, mockAdd };
  }

  test("スナップショットがnullの場合はスキップ", async () => {
    const event = { data: null, params: { appId: "app-1", inspectionId: "insp-1" } };
    await handleInspectionCreated(event);
    expect(firestoreMock.batch).not.toHaveBeenCalled();
  });

  test("result が 'passed' の場合は何もしない", async () => {
    const event = createMockFirestoreEvent(
      { result: "passed" },
      { appId: "app-1", inspectionId: "insp-1" },
    );
    await handleInspectionCreated(event);

    // バッチ通知もワーカー通知も実行されない
    expect(firestoreMock.batch).not.toHaveBeenCalled();
    expect(firestoreMock.collection).not.toHaveBeenCalled();
  });

  test("result が 'failed' の場合、管理者とワーカー両方に通知する", async () => {
    const { mockBatch, mockAdd } = setupMocks({
      adminUids: ["admin-1"],
      appData: { applicantUid: "worker-001" },
    });

    const event = createMockFirestoreEvent(
      { result: "failed" },
      { appId: "app-10", inspectionId: "insp-20" },
    );

    await handleInspectionCreated(event);

    // 管理者通知（バッチ）
    expect(mockBatch.set).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({
        title: "検査不合格",
        body: "検査結果: 不合格",
        type: "inspection_failed",
        data: { applicationId: "app-10", inspectionId: "insp-20" },
      }),
    );
    expect(mockBatch.commit).toHaveBeenCalled();

    // ワーカー通知（add）
    expect(mockAdd).toHaveBeenCalledWith(
      expect.objectContaining({
        targetUid: "worker-001",
        title: "検査結果",
        body: "検査が不合格でした。修正をお願いします。",
        type: "inspection_result",
        data: { applicationId: "app-10" },
        read: false,
        createdAt: "SERVER_TIMESTAMP",
      }),
    );
  });

  test("result が 'partial' の場合も管理者とワーカーに通知する", async () => {
    const { mockBatch, mockAdd } = setupMocks({
      adminUids: ["admin-1"],
      appData: { applicantUid: "worker-002" },
    });

    const event = createMockFirestoreEvent(
      { result: "partial" },
      { appId: "app-11", inspectionId: "insp-21" },
    );

    await handleInspectionCreated(event);

    // 管理者通知: 一部不合格の文言
    expect(mockBatch.set).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({
        body: "検査結果: 一部不合格",
      }),
    );

    // ワーカー通知: partial 用の文言
    expect(mockAdd).toHaveBeenCalledWith(
      expect.objectContaining({
        targetUid: "worker-002",
        body: "検査で一部不合格の項目があります。",
      }),
    );
  });

  test("ワーカーの応募ドキュメントが存在しない場合はワーカー通知をスキップ", async () => {
    const { mockBatch, mockAdd } = setupMocks({
      adminUids: ["admin-1"],
      appData: null, // 応募ドキュメント無し
    });

    const event = createMockFirestoreEvent(
      { result: "failed" },
      { appId: "app-missing", inspectionId: "insp-30" },
    );

    await handleInspectionCreated(event);

    // 管理者通知は実行される
    expect(mockBatch.commit).toHaveBeenCalled();

    // ワーカー通知は実行されない
    expect(mockAdd).not.toHaveBeenCalled();
  });

  test("applicantUid が未設定の場合はワーカー通知をスキップ", async () => {
    const { mockBatch, mockAdd } = setupMocks({
      adminUids: ["admin-1"],
      appData: { applicantUid: null }, // UID が null
    });

    const event = createMockFirestoreEvent(
      { result: "failed" },
      { appId: "app-12", inspectionId: "insp-31" },
    );

    await handleInspectionCreated(event);

    // 管理者通知は実行される
    expect(mockBatch.commit).toHaveBeenCalled();

    // ワーカー通知は実行されない（applicantUid が falsy）
    expect(mockAdd).not.toHaveBeenCalled();
  });
});

// ========================================================
// sendDailySummary のロジック
// ========================================================
describe("sendDailySummary", () => {
  let firestoreMock;

  beforeEach(() => {
    jest.clearAllMocks();
    firestoreMock = admin.firestore();
  });

  async function getAdminUids() {
    const doc = await firestoreMock.doc("config/admins").get();
    if (!doc.exists) return [];
    return doc.data().adminUids || [];
  }

  async function notifyAdmins(title, body, type, data = {}) {
    const adminUids = await getAdminUids();
    const batch = firestoreMock.batch();
    for (const uid of adminUids) {
      const ref = firestoreMock.collection("notifications").doc();
      batch.set(ref, {
        targetUid: uid,
        title,
        body,
        type,
        data,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    logger.info(`Notified ${adminUids.length} admins`, { type });
  }

  async function handleDailySummary() {
    try {
      // 未処理件数を集計
      const [pendingApps, pendingQuals, pendingReports] = await Promise.all([
        firestoreMock.collection("applications")
          .where("status", "==", "applied").count().get(),
        firestoreMock.collectionGroup("qualifications_v2")
          .where("verificationStatus", "==", "pending").count().get(),
        firestoreMock.collectionGroup("work_reports")
          .where("reviewStatus", "==", "pending").count().get(),
      ]);

      const apps = pendingApps.data().count;
      const quals = pendingQuals.data().count;
      const reports = pendingReports.data().count;
      const total = apps + quals + reports;

      if (total === 0) {
        logger.info("No pending items for daily summary");
        return;
      }

      const parts = [];
      if (apps > 0) parts.push(`未処理応募: ${apps}件`);
      if (quals > 0) parts.push(`資格承認待ち: ${quals}件`);
      if (reports > 0) parts.push(`未レビュー日報: ${reports}件`);

      await notifyAdmins(
        "日次サマリー",
        parts.join("、"),
        "daily_summary",
        { pendingApps: apps, pendingQuals: quals, pendingReports: reports },
      );
    } catch (e) {
      logger.error("sendDailySummary failed", e);
    }
  }

  // collection / collectionGroup のチェーン呼び出しモック生成
  function createCountMock(countValue) {
    return {
      where: jest.fn().mockReturnValue({
        count: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue({
            data: () => ({ count: countValue }),
          }),
        }),
      }),
    };
  }

  function setupDailySummaryMocks({ apps = 0, quals = 0, reports = 0, adminUids = ["admin-1"] } = {}) {
    // doc("config/admins") のモック
    firestoreMock.doc.mockReturnValue({
      get: jest.fn().mockResolvedValue({
        exists: true,
        data: () => ({ adminUids }),
      }),
    });

    // collection / collectionGroup のモック
    const appsMock = createCountMock(apps);
    const qualsMock = createCountMock(quals);
    const reportsMock = createCountMock(reports);

    firestoreMock.collection.mockImplementation((name) => {
      if (name === "applications") return appsMock;
      // notifications 用（notifyAdmins 内で使う）
      return {
        doc: jest.fn().mockReturnValue({ id: "notif-doc" }),
      };
    });

    firestoreMock.collectionGroup.mockImplementation((name) => {
      if (name === "qualifications_v2") return qualsMock;
      if (name === "work_reports") return reportsMock;
      return createCountMock(0);
    });

    const mockBatch = {
      set: jest.fn(),
      commit: jest.fn().mockResolvedValue(undefined),
    };
    firestoreMock.batch.mockReturnValue(mockBatch);

    return { mockBatch };
  }

  test("未処理アイテムが0件の場合は通知しない", async () => {
    setupDailySummaryMocks({ apps: 0, quals: 0, reports: 0 });

    await handleDailySummary();

    expect(logger.info).toHaveBeenCalledWith("No pending items for daily summary");
    expect(firestoreMock.batch).not.toHaveBeenCalled();
  });

  test("未処理アイテムがある場合にサマリー通知を送る", async () => {
    const { mockBatch } = setupDailySummaryMocks({
      apps: 3,
      quals: 1,
      reports: 2,
      adminUids: ["admin-1"],
    });

    await handleDailySummary();

    expect(mockBatch.set).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({
        title: "日次サマリー",
        body: "未処理応募: 3件、資格承認待ち: 1件、未レビュー日報: 2件",
        type: "daily_summary",
        data: { pendingApps: 3, pendingQuals: 1, pendingReports: 2 },
      }),
    );
    expect(mockBatch.commit).toHaveBeenCalled();
  });

  test("一部のカテゴリのみ件数がある場合は該当分のみ表示", async () => {
    const { mockBatch } = setupDailySummaryMocks({
      apps: 5,
      quals: 0,
      reports: 0,
      adminUids: ["admin-1"],
    });

    await handleDailySummary();

    expect(mockBatch.set).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({
        body: "未処理応募: 5件",
      }),
    );
  });
});

// ========================================================
// sendChatUnreadReminder のロジック
// ========================================================
describe("sendChatUnreadReminder", () => {
  let firestoreMock;
  let messagingMock;

  beforeEach(() => {
    jest.clearAllMocks();
    firestoreMock = admin.firestore();
    messagingMock = admin.messaging();
  });

  async function getAdminUids() {
    const doc = await firestoreMock.doc("config/admins").get();
    if (!doc.exists) return [];
    return doc.data().adminUids || [];
  }

  async function handleChatUnreadReminder() {
    try {
      const adminUids = await getAdminUids();

      for (const uid of adminUids) {
        const unreadSnap = await firestoreMock.collection("notifications")
          .where("targetUid", "==", uid)
          .where("read", "==", false)
          .count()
          .get();

        const unreadCount = unreadSnap.data().count;
        if (unreadCount >= 5) {
          // FCMプッシュ通知
          const profileSnap = await firestoreMock.doc(`profiles/${uid}`).get();
          const token = profileSnap.exists ? (profileSnap.data() || {}).fcmToken : null;
          if (token) {
            await messagingMock.send({
              token,
              notification: {
                title: "未読通知リマインド",
                body: `未読の通知が${unreadCount}件あります`,
              },
              data: { type: "unread_reminder" },
            });
            logger.info("Sent unread reminder", { uid, unreadCount });
          }
        }
      }
    } catch (e) {
      logger.error("sendChatUnreadReminder failed", e);
    }
  }

  test("未読数が5件以上の場合にFCMプッシュ通知を送る", async () => {
    // doc() のモック: パスに応じて返す
    firestoreMock.doc.mockImplementation((path) => {
      if (path === "config/admins") {
        return {
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({ adminUids: ["admin-1"] }),
          }),
        };
      }
      if (path === "profiles/admin-1") {
        return {
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({ fcmToken: "fcm-token-admin-1" }),
          }),
        };
      }
      return {
        get: jest.fn().mockResolvedValue({ exists: false, data: () => null }),
      };
    });

    // collection("notifications").where().where().count().get() のチェーンモック
    firestoreMock.collection.mockReturnValue({
      where: jest.fn().mockReturnValue({
        where: jest.fn().mockReturnValue({
          count: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue({
              data: () => ({ count: 7 }),
            }),
          }),
        }),
      }),
    });

    await handleChatUnreadReminder();

    expect(messagingMock.send).toHaveBeenCalledWith({
      token: "fcm-token-admin-1",
      notification: {
        title: "未読通知リマインド",
        body: "未読の通知が7件あります",
      },
      data: { type: "unread_reminder" },
    });
    expect(logger.info).toHaveBeenCalledWith(
      "Sent unread reminder",
      { uid: "admin-1", unreadCount: 7 },
    );
  });

  test("未読数が5件未満の場合はFCMを送らない", async () => {
    firestoreMock.doc.mockImplementation((path) => {
      if (path === "config/admins") {
        return {
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({ adminUids: ["admin-1"] }),
          }),
        };
      }
      return {
        get: jest.fn().mockResolvedValue({ exists: false, data: () => null }),
      };
    });

    // 未読4件（閾値未満）
    firestoreMock.collection.mockReturnValue({
      where: jest.fn().mockReturnValue({
        where: jest.fn().mockReturnValue({
          count: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue({
              data: () => ({ count: 4 }),
            }),
          }),
        }),
      }),
    });

    await handleChatUnreadReminder();

    // FCMは送信されない
    expect(messagingMock.send).not.toHaveBeenCalled();
  });

  test("未読数がちょうど5件の場合はFCMを送る（境界値）", async () => {
    firestoreMock.doc.mockImplementation((path) => {
      if (path === "config/admins") {
        return {
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({ adminUids: ["admin-1"] }),
          }),
        };
      }
      if (path === "profiles/admin-1") {
        return {
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({ fcmToken: "token-abc" }),
          }),
        };
      }
      return {
        get: jest.fn().mockResolvedValue({ exists: false, data: () => null }),
      };
    });

    // ちょうど5件
    firestoreMock.collection.mockReturnValue({
      where: jest.fn().mockReturnValue({
        where: jest.fn().mockReturnValue({
          count: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue({
              data: () => ({ count: 5 }),
            }),
          }),
        }),
      }),
    });

    await handleChatUnreadReminder();

    expect(messagingMock.send).toHaveBeenCalledWith(
      expect.objectContaining({
        token: "token-abc",
        notification: expect.objectContaining({
          body: "未読の通知が5件あります",
        }),
      }),
    );
  });

  test("FCMトークンがない場合はFCMを送信しない", async () => {
    firestoreMock.doc.mockImplementation((path) => {
      if (path === "config/admins") {
        return {
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({ adminUids: ["admin-1"] }),
          }),
        };
      }
      if (path === "profiles/admin-1") {
        return {
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({ fcmToken: null }),
          }),
        };
      }
      return {
        get: jest.fn().mockResolvedValue({ exists: false, data: () => null }),
      };
    });

    // 未読10件（閾値以上）
    firestoreMock.collection.mockReturnValue({
      where: jest.fn().mockReturnValue({
        where: jest.fn().mockReturnValue({
          count: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue({
              data: () => ({ count: 10 }),
            }),
          }),
        }),
      }),
    });

    await handleChatUnreadReminder();

    // トークンがないのでFCMは送信しない
    expect(messagingMock.send).not.toHaveBeenCalled();
  });

  test("複数管理者で一部のみ未読5件以上の場合、該当者だけにFCMを送る", async () => {
    firestoreMock.doc.mockImplementation((path) => {
      if (path === "config/admins") {
        return {
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({ adminUids: ["admin-1", "admin-2"] }),
          }),
        };
      }
      if (path === "profiles/admin-2") {
        return {
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({ fcmToken: "token-admin-2" }),
          }),
        };
      }
      return {
        get: jest.fn().mockResolvedValue({ exists: false, data: () => null }),
      };
    });

    // admin-1 は未読2件、admin-2 は未読8件
    let callIndex = 0;
    firestoreMock.collection.mockReturnValue({
      where: jest.fn().mockReturnValue({
        where: jest.fn().mockReturnValue({
          count: jest.fn().mockReturnValue({
            get: jest.fn().mockImplementation(() => {
              callIndex++;
              // 1回目の呼び出し = admin-1（未読2件）
              // 2回目の呼び出し = admin-2（未読8件）
              const count = callIndex === 1 ? 2 : 8;
              return Promise.resolve({ data: () => ({ count }) });
            }),
          }),
        }),
      }),
    });

    await handleChatUnreadReminder();

    // admin-2 だけにFCMが送られる
    expect(messagingMock.send).toHaveBeenCalledTimes(1);
    expect(messagingMock.send).toHaveBeenCalledWith(
      expect.objectContaining({
        token: "token-admin-2",
        notification: expect.objectContaining({
          body: "未読の通知が8件あります",
        }),
      }),
    );
  });
});
