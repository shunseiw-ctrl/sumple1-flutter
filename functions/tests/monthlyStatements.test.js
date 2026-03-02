const admin = require("firebase-admin");

// firebase-admin をモック
jest.mock("firebase-admin", () => {
  const firestoreMock = {
    collection: jest.fn(),
    doc: jest.fn(),
    batch: jest.fn(),
  };
  firestoreMock.FieldValue = {
    serverTimestamp: jest.fn().mockReturnValue("SERVER_TIMESTAMP"),
  };
  return {
    initializeApp: jest.fn(),
    firestore: Object.assign(jest.fn(() => firestoreMock), {
      FieldValue: {
        serverTimestamp: jest.fn().mockReturnValue("SERVER_TIMESTAMP"),
      },
    }),
  };
});

jest.mock("firebase-functions/logger", () => ({
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
}));

describe("monthlyStatements", () => {
  let firestoreMock;

  beforeEach(() => {
    jest.clearAllMocks();
    firestoreMock = admin.firestore();
  });

  // onEarningCreated ロジック再現
  async function handleOnEarningCreated(earningData) {
    const db = firestoreMock;
    const workerUid = earningData.uid;
    const amount = Number.isInteger(earningData.amount) ? earningData.amount : 0;
    const applicationId = earningData.applicationId || "";
    const projectName = earningData.projectNameSnapshot || "案件";

    if (!workerUid) return;

    let month = "";
    let completedDate = "";
    const payoutConfirmedAt = earningData.payoutConfirmedAt;
    if (payoutConfirmedAt && payoutConfirmedAt.toDate) {
      const d = payoutConfirmedAt.toDate();
      const mm = String(d.getMonth() + 1).padStart(2, "0");
      month = `${d.getFullYear()}-${mm}`;
      completedDate = `${d.getFullYear()}-${mm}-${String(d.getDate()).padStart(2, "0")}`;
    } else {
      const now = new Date();
      const mm = String(now.getMonth() + 1).padStart(2, "0");
      month = `${now.getFullYear()}-${mm}`;
      completedDate = `${now.getFullYear()}-${mm}-${String(now.getDate()).padStart(2, "0")}`;
    }

    const [yearStr, monthStr] = month.split("-");
    const year = parseInt(yearStr, 10);
    const mon = parseInt(monthStr, 10);
    const nextMonth = mon === 12 ? 1 : mon + 1;
    const nextYear = mon === 12 ? year + 1 : year;
    const paymentDate = `${nextYear}-${String(nextMonth).padStart(2, "0")}-10`;

    const existingSnap = await db
      .collection("monthly_statements")
      .where("workerUid", "==", workerUid)
      .where("month", "==", month)
      .limit(1)
      .get();

    const newItem = { applicationId, jobTitle: projectName, completedDate, amount };

    if (existingSnap.empty) {
      await db.collection("monthly_statements").add({
        workerUid,
        month,
        items: [newItem],
        totalAmount: amount,
        netAmount: amount,
        status: "draft",
        paymentDate,
        earlyPaymentRequested: false,
      });
    } else {
      const docRef = existingSnap.docs[0].ref;
      const existing = existingSnap.docs[0].data();
      const items = existing.items || [];
      items.push(newItem);
      const totalAmount = items.reduce((acc, item) => acc + (item.amount || 0), 0);

      await docRef.update({ items, totalAmount, netAmount: totalAmount });
    }

    return { month, paymentDate };
  }

  // confirmMonthlyStatements ロジック再現
  async function handleConfirmMonthlyStatements(currentMonth) {
    const db = firestoreMock;
    const drafts = await db
      .collection("monthly_statements")
      .where("status", "==", "draft")
      .get();

    const updated = [];
    for (const doc of drafts.docs) {
      const data = doc.data();
      if (data.month >= currentMonth) continue;
      await doc.ref.update({ status: "confirmed" });
      updated.push(doc);
    }
    return updated;
  }

  describe("onEarningCreated", () => {
    test("新規明細ドキュメント作成", async () => {
      const addFn = jest.fn().mockResolvedValue({ id: "stmt-new" });
      const queryMock = {
        empty: true,
        docs: [],
      };

      firestoreMock.collection.mockReturnValue({
        where: jest.fn().mockReturnValue({
          where: jest.fn().mockReturnValue({
            limit: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue(queryMock),
            }),
          }),
        }),
        add: addFn,
      });

      const result = await handleOnEarningCreated({
        uid: "worker-001",
        amount: 50000,
        applicationId: "app-001",
        projectNameSnapshot: "内装工事",
        payoutConfirmedAt: { toDate: () => new Date(2025, 3, 15) }, // 2025-04-15
      });

      expect(addFn).toHaveBeenCalledWith(
        expect.objectContaining({
          workerUid: "worker-001",
          month: "2025-04",
          totalAmount: 50000,
          status: "draft",
          paymentDate: "2025-05-10",
        }),
      );
    });

    test("既存明細にline item追加", async () => {
      const updateFn = jest.fn().mockResolvedValue(undefined);
      const existingDoc = {
        ref: { update: updateFn },
        data: () => ({
          items: [{ applicationId: "app-001", jobTitle: "既存", completedDate: "2025-04-10", amount: 30000 }],
          totalAmount: 30000,
        }),
      };
      const queryMock = { empty: false, docs: [existingDoc] };

      firestoreMock.collection.mockReturnValue({
        where: jest.fn().mockReturnValue({
          where: jest.fn().mockReturnValue({
            limit: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue(queryMock),
            }),
          }),
        }),
      });

      await handleOnEarningCreated({
        uid: "worker-001",
        amount: 20000,
        applicationId: "app-002",
        projectNameSnapshot: "外壁工事",
        payoutConfirmedAt: { toDate: () => new Date(2025, 3, 20) },
      });

      expect(updateFn).toHaveBeenCalledWith(
        expect.objectContaining({
          totalAmount: 50000,
          netAmount: 50000,
        }),
      );
      // itemsが2件になっている
      const call = updateFn.mock.calls[0][0];
      expect(call.items).toHaveLength(2);
    });

    test("totalAmount正算", async () => {
      const updateFn = jest.fn().mockResolvedValue(undefined);
      const existingDoc = {
        ref: { update: updateFn },
        data: () => ({
          items: [
            { applicationId: "app-001", amount: 30000 },
            { applicationId: "app-002", amount: 25000 },
          ],
          totalAmount: 55000,
        }),
      };
      const queryMock = { empty: false, docs: [existingDoc] };

      firestoreMock.collection.mockReturnValue({
        where: jest.fn().mockReturnValue({
          where: jest.fn().mockReturnValue({
            limit: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue(queryMock),
            }),
          }),
        }),
      });

      await handleOnEarningCreated({
        uid: "worker-001",
        amount: 15000,
        applicationId: "app-003",
        projectNameSnapshot: "追加工事",
        payoutConfirmedAt: { toDate: () => new Date(2025, 3, 25) },
      });

      const call = updateFn.mock.calls[0][0];
      expect(call.totalAmount).toBe(70000); // 30000 + 25000 + 15000
    });

    test("paymentDateが翌月10日", async () => {
      const addFn = jest.fn().mockResolvedValue({ id: "stmt-new" });
      firestoreMock.collection.mockReturnValue({
        where: jest.fn().mockReturnValue({
          where: jest.fn().mockReturnValue({
            limit: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue({ empty: true, docs: [] }),
            }),
          }),
        }),
        add: addFn,
      });

      // 12月 → 翌年1月10日
      await handleOnEarningCreated({
        uid: "worker-001",
        amount: 10000,
        applicationId: "app-001",
        projectNameSnapshot: "テスト",
        payoutConfirmedAt: { toDate: () => new Date(2025, 11, 15) }, // 2025-12-15
      });

      expect(addFn).toHaveBeenCalledWith(
        expect.objectContaining({
          paymentDate: "2026-01-10",
        }),
      );
    });
  });

  describe("confirmMonthlyStatements", () => {
    test("draftをconfirmedに更新", async () => {
      const updateFn1 = jest.fn().mockResolvedValue(undefined);
      const updateFn2 = jest.fn().mockResolvedValue(undefined);
      const docs = [
        { ref: { update: updateFn1 }, data: () => ({ month: "2025-03", status: "draft" }) },
        { ref: { update: updateFn2 }, data: () => ({ month: "2025-02", status: "draft" }) },
      ];

      firestoreMock.collection.mockReturnValue({
        where: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue({ docs }),
        }),
      });

      const updated = await handleConfirmMonthlyStatements("2025-04");
      expect(updated).toHaveLength(2);
      expect(updateFn1).toHaveBeenCalledWith(expect.objectContaining({ status: "confirmed" }));
      expect(updateFn2).toHaveBeenCalledWith(expect.objectContaining({ status: "confirmed" }));
    });

    test("当月のdraftは変更しない", async () => {
      const updateFn = jest.fn().mockResolvedValue(undefined);
      const docs = [
        { ref: { update: updateFn }, data: () => ({ month: "2025-04", status: "draft" }) },
      ];

      firestoreMock.collection.mockReturnValue({
        where: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue({ docs }),
        }),
      });

      const updated = await handleConfirmMonthlyStatements("2025-04");
      expect(updated).toHaveLength(0);
      expect(updateFn).not.toHaveBeenCalled();
    });
  });
});
