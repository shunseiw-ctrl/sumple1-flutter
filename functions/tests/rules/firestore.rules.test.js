const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");
const fs = require("fs");
const path = require("path");

const PROJECT_ID = "alba-work-test";

let testEnv;

beforeAll(async () => {
  const rulesPath = path.resolve(__dirname, "../../../firestore.rules");
  const rules = fs.readFileSync(rulesPath, "utf8");

  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules },
  });
});

afterAll(async () => {
  if (testEnv) await testEnv.cleanup();
});

afterEach(async () => {
  if (testEnv) await testEnv.clearFirestore();
});

function getAuthContext(uid, extra = {}) {
  return testEnv.authenticatedContext(uid, extra);
}

function getUnauthContext() {
  return testEnv.unauthenticatedContext();
}

// Admin helper: config/admins に adminUid を設定
async function setupAdmin(adminUid) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc("config/admins").set({
      adminUids: [adminUid],
      emails: ["admin@albawork.com"],
    });
  });
}

// ============================
// jobs コレクション
// ============================
describe("jobs", () => {
  test("anyone can read jobs (public)", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("jobs/job1").set({
        title: "Test", location: "Tokyo", price: "1000", date: "2026-01-01",
        ownerId: "user1",
      });
    });

    const unauth = getUnauthContext();
    await assertSucceeds(unauth.firestore().doc("jobs/job1").get());
  });

  test("signed-in user can create job with valid data", async () => {
    const ctx = getAuthContext("user1");
    await assertSucceeds(
      ctx.firestore().collection("jobs").add({
        title: "内装工事",
        location: "東京都千代田区",
        price: "15000",
        date: "2026-03-15",
        ownerId: "user1",
      }),
    );
  });

  test("reject create when title exceeds 100 chars", async () => {
    const ctx = getAuthContext("user1");
    await assertFails(
      ctx.firestore().collection("jobs").add({
        title: "a".repeat(101),
        location: "Tokyo",
        price: "1000",
        date: "2026-01-01",
        ownerId: "user1",
      }),
    );
  });

  test("reject create when location exceeds 200 chars", async () => {
    const ctx = getAuthContext("user1");
    await assertFails(
      ctx.firestore().collection("jobs").add({
        title: "Test",
        location: "a".repeat(201),
        price: "1000",
        date: "2026-01-01",
        ownerId: "user1",
      }),
    );
  });

  test("owner can delete own job", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("jobs/job1").set({
        title: "Test", location: "Tokyo", price: "1000", date: "2026-01-01",
        ownerId: "user1",
      });
    });

    const ctx = getAuthContext("user1");
    await assertSucceeds(ctx.firestore().doc("jobs/job1").delete());
  });

  test("non-owner cannot delete job", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("jobs/job1").set({
        title: "Test", location: "Tokyo", price: "1000", date: "2026-01-01",
        ownerId: "user1",
      });
    });

    const ctx = getAuthContext("user2");
    await assertFails(ctx.firestore().doc("jobs/job1").delete());
  });

  test("admin can delete any job", async () => {
    await setupAdmin("admin1");
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("jobs/job1").set({
        title: "Test", location: "Tokyo", price: "1000", date: "2026-01-01",
        ownerId: "user1",
      });
    });

    const ctx = getAuthContext("admin1");
    await assertSucceeds(ctx.firestore().doc("jobs/job1").delete());
  });
});

// ============================
// applications コレクション
// ============================
describe("applications", () => {
  test("applicant can read own application", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("applications/app1").set({
        applicantUid: "user1", adminUid: "admin1", jobId: "job1",
        status: "applied", projectNameSnapshot: "Test",
      });
    });

    const ctx = getAuthContext("user1");
    await assertSucceeds(ctx.firestore().doc("applications/app1").get());
  });

  test("other user cannot read application", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("applications/app1").set({
        applicantUid: "user1", adminUid: "admin1", jobId: "job1",
        status: "applied", projectNameSnapshot: "Test",
      });
    });

    const ctx = getAuthContext("user2");
    await assertFails(ctx.firestore().doc("applications/app1").get());
  });

  test("applicant can create application with status=applied", async () => {
    const ctx = getAuthContext("user1");
    await assertSucceeds(
      ctx.firestore().collection("applications").add({
        applicantUid: "user1",
        adminUid: "admin1",
        jobId: "job1",
        status: "applied",
        projectNameSnapshot: "Test project",
      }),
    );
  });

  test("reject create with status != applied", async () => {
    const ctx = getAuthContext("user1");
    await assertFails(
      ctx.firestore().collection("applications").add({
        applicantUid: "user1",
        adminUid: "admin1",
        jobId: "job1",
        status: "assigned",
        projectNameSnapshot: "Test project",
      }),
    );
  });

  test("delete is always rejected", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("applications/app1").set({
        applicantUid: "user1", adminUid: "admin1", jobId: "job1",
        status: "applied", projectNameSnapshot: "Test",
      });
    });
    await setupAdmin("admin1");

    const ctx = getAuthContext("admin1");
    await assertFails(ctx.firestore().doc("applications/app1").delete());
  });
});

// ============================
// profiles コレクション
// ============================
describe("profiles", () => {
  test("user can read own profile", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("profiles/user1").set({
        displayName: "Test User",
      });
    });

    const ctx = getAuthContext("user1");
    await assertSucceeds(ctx.firestore().doc("profiles/user1").get());
  });

  test("user cannot read other profiles", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("profiles/user2").set({
        displayName: "Other User",
      });
    });

    const ctx = getAuthContext("user1");
    await assertFails(ctx.firestore().doc("profiles/user2").get());
  });

  test("admin can read any profile", async () => {
    await setupAdmin("admin1");
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("profiles/user1").set({
        displayName: "Test User",
      });
    });

    const ctx = getAuthContext("admin1");
    await assertSucceeds(ctx.firestore().doc("profiles/user1").get());
  });

  test("user can create own profile", async () => {
    const ctx = getAuthContext("user1");
    await assertSucceeds(
      ctx.firestore().doc("profiles/user1").set({
        displayName: "Test",
      }),
    );
  });

  test("user cannot create other user profile", async () => {
    const ctx = getAuthContext("user1");
    await assertFails(
      ctx.firestore().doc("profiles/user2").set({
        displayName: "Test",
      }),
    );
  });

  test("reject displayName exceeding 50 chars", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("profiles/user1").set({
        displayName: "Test",
      });
    });

    const ctx = getAuthContext("user1");
    await assertFails(
      ctx.firestore().doc("profiles/user1").update({
        displayName: "a".repeat(51),
      }),
    );
  });

  test("delete is always rejected", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("profiles/user1").set({ displayName: "Test" });
    });

    const ctx = getAuthContext("user1");
    await assertFails(ctx.firestore().doc("profiles/user1").delete());
  });
});

// ============================
// notifications コレクション
// ============================
describe("notifications", () => {
  test("user can read own notifications", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("notifications/n1").set({
        targetUid: "user1", title: "Test", body: "Body",
      });
    });

    const ctx = getAuthContext("user1");
    await assertSucceeds(ctx.firestore().doc("notifications/n1").get());
  });

  test("user cannot read other user notifications", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("notifications/n1").set({
        targetUid: "user2", title: "Test", body: "Body",
      });
    });

    const ctx = getAuthContext("user1");
    await assertFails(ctx.firestore().doc("notifications/n1").get());
  });

  test("user can only update read field", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("notifications/n1").set({
        targetUid: "user1", title: "Test", body: "Body", read: false,
      });
    });

    const ctx = getAuthContext("user1");
    await assertSucceeds(
      ctx.firestore().doc("notifications/n1").update({ read: true }),
    );
  });

  test("user cannot update title of notification", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("notifications/n1").set({
        targetUid: "user1", title: "Test", body: "Body", read: false,
      });
    });

    const ctx = getAuthContext("user1");
    await assertFails(
      ctx.firestore().doc("notifications/n1").update({ title: "Changed" }),
    );
  });

  test("delete is always rejected", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("notifications/n1").set({
        targetUid: "user1", title: "Test", body: "Body",
      });
    });

    const ctx = getAuthContext("user1");
    await assertFails(ctx.firestore().doc("notifications/n1").delete());
  });
});

// ============================
// stats コレクション
// ============================
describe("stats", () => {
  test("admin can read stats", async () => {
    await setupAdmin("admin1");
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("stats/realtime").set({ totalJobs: 10 });
    });

    const ctx = getAuthContext("admin1");
    await assertSucceeds(ctx.firestore().doc("stats/realtime").get());
  });

  test("non-admin cannot read stats", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("stats/realtime").set({ totalJobs: 10 });
    });

    const ctx = getAuthContext("user1");
    await assertFails(ctx.firestore().doc("stats/realtime").get());
  });

  test("nobody can write stats", async () => {
    await setupAdmin("admin1");
    const ctx = getAuthContext("admin1");
    await assertFails(
      ctx.firestore().doc("stats/realtime").set({ totalJobs: 99 }),
    );
  });
});

// ============================
// earnings コレクション
// ============================
describe("earnings", () => {
  test("admin can create earnings", async () => {
    await setupAdmin("admin1");
    const ctx = getAuthContext("admin1");
    await assertSucceeds(
      ctx.firestore().collection("earnings").add({
        uid: "user1",
        applicationId: "app1",
        projectNameSnapshot: "Test",
        amount: 10000,
        payoutConfirmedAt: new Date(),
      }),
    );
  });

  test("non-admin cannot create earnings", async () => {
    const ctx = getAuthContext("user1");
    await assertFails(
      ctx.firestore().collection("earnings").add({
        uid: "user1",
        applicationId: "app1",
        projectNameSnapshot: "Test",
        amount: 10000,
        payoutConfirmedAt: new Date(),
      }),
    );
  });

  test("user can read own earnings", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("earnings/e1").set({
        uid: "user1", amount: 10000, applicationId: "app1",
        projectNameSnapshot: "Test", payoutConfirmedAt: new Date(),
      });
    });

    const ctx = getAuthContext("user1");
    await assertSucceeds(ctx.firestore().doc("earnings/e1").get());
  });

  test("user cannot read other user earnings", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("earnings/e1").set({
        uid: "user2", amount: 10000, applicationId: "app1",
        projectNameSnapshot: "Test", payoutConfirmedAt: new Date(),
      });
    });

    const ctx = getAuthContext("user1");
    await assertFails(ctx.firestore().doc("earnings/e1").get());
  });

  test("reject projectNameSnapshot exceeding 200 chars", async () => {
    await setupAdmin("admin1");
    const ctx = getAuthContext("admin1");
    await assertFails(
      ctx.firestore().collection("earnings").add({
        uid: "user1",
        applicationId: "app1",
        projectNameSnapshot: "a".repeat(201),
        amount: 10000,
        payoutConfirmedAt: new Date(),
      }),
    );
  });
});

// ============================
// favorites コレクション
// ============================
describe("favorites", () => {
  test("user can read/write own favorites", async () => {
    const ctx = getAuthContext("user1");
    await assertSucceeds(
      ctx.firestore().doc("favorites/user1").set({ jobIds: ["job1"] }),
    );
    await assertSucceeds(ctx.firestore().doc("favorites/user1").get());
  });

  test("user cannot read other user favorites", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("favorites/user2").set({ jobIds: ["job1"] });
    });

    const ctx = getAuthContext("user1");
    await assertFails(ctx.firestore().doc("favorites/user2").get());
  });
});

// ============================
// KPI コレクション
// ============================
describe("kpi_daily", () => {
  test("admin can read kpi_daily", async () => {
    await setupAdmin("admin1");
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("kpi_daily/2026-03-01").set({ newUsers: 5 });
    });

    const ctx = getAuthContext("admin1");
    await assertSucceeds(ctx.firestore().doc("kpi_daily/2026-03-01").get());
  });

  test("non-admin cannot read kpi_daily", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("kpi_daily/2026-03-01").set({ newUsers: 5 });
    });

    const ctx = getAuthContext("user1");
    await assertFails(ctx.firestore().doc("kpi_daily/2026-03-01").get());
  });

  test("nobody can write kpi_daily", async () => {
    await setupAdmin("admin1");
    const ctx = getAuthContext("admin1");
    await assertFails(
      ctx.firestore().doc("kpi_daily/2026-03-01").set({ newUsers: 99 }),
    );
  });
});

describe("kpi_monthly", () => {
  test("admin can read kpi_monthly", async () => {
    await setupAdmin("admin1");
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("kpi_monthly/2026-03").set({ mau: 100 });
    });

    const ctx = getAuthContext("admin1");
    await assertSucceeds(ctx.firestore().doc("kpi_monthly/2026-03").get());
  });

  test("nobody can write kpi_monthly", async () => {
    await setupAdmin("admin1");
    const ctx = getAuthContext("admin1");
    await assertFails(
      ctx.firestore().doc("kpi_monthly/2026-03").set({ mau: 999 }),
    );
  });
});

// ============================
// LINE認証コレクション
// ============================
describe("line_auth_states", () => {
  test("nobody can read line_auth_states", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("line_auth_states/state1").set({ createdAt: new Date() });
    });

    const ctx = getAuthContext("user1");
    await assertFails(ctx.firestore().doc("line_auth_states/state1").get());
  });

  test("nobody can write line_auth_states", async () => {
    const ctx = getAuthContext("user1");
    await assertFails(
      ctx.firestore().doc("line_auth_states/state1").set({ createdAt: new Date() }),
    );
  });
});

describe("line_auth_tokens", () => {
  test("nobody can read line_auth_tokens", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("line_auth_tokens/token1").set({ customToken: "abc" });
    });

    const ctx = getAuthContext("user1");
    await assertFails(ctx.firestore().doc("line_auth_tokens/token1").get());
  });

  test("nobody can write line_auth_tokens", async () => {
    const ctx = getAuthContext("user1");
    await assertFails(
      ctx.firestore().doc("line_auth_tokens/token1").set({ customToken: "abc" }),
    );
  });
});

// ============================
// catch-all ルール
// ============================
describe("catch-all rule", () => {
  test("unknown collections are denied", async () => {
    const ctx = getAuthContext("user1");
    await assertFails(ctx.firestore().doc("unknown/doc1").get());
    await assertFails(ctx.firestore().doc("unknown/doc1").set({ data: true }));
  });
});
