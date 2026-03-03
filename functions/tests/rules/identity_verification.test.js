const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");
const fs = require("fs");
const path = require("path");

const PROJECT_ID = "alba-work-iv-test";

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

async function setupAdmin(adminUid) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc("config/admins").set({
      adminUids: [adminUid],
      emails: ["admin@albawork.com"],
    });
  });
}

describe("identity_verification", () => {
  test("owner can read own document", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("identity_verification/user1").set({
        uid: "user1",
        idPhotoUrl: "https://example.com/id.jpg",
        selfieUrl: "https://example.com/selfie.jpg",
        status: "pending",
      });
    });

    const ctx = getAuthContext("user1");
    await assertSucceeds(
      ctx.firestore().doc("identity_verification/user1").get()
    );
  });

  test("admin can read any document", async () => {
    await setupAdmin("admin1");
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("identity_verification/user1").set({
        uid: "user1",
        idPhotoUrl: "https://example.com/id.jpg",
        selfieUrl: "https://example.com/selfie.jpg",
        status: "pending",
      });
    });

    const ctx = getAuthContext("admin1");
    await assertSucceeds(
      ctx.firestore().doc("identity_verification/user1").get()
    );
  });

  test("create succeeds with valid data", async () => {
    const ctx = getAuthContext("user1");
    await assertSucceeds(
      ctx.firestore().doc("identity_verification/user1").set({
        uid: "user1",
        idPhotoUrl: "https://example.com/id.jpg",
        selfieUrl: "https://example.com/selfie.jpg",
        status: "pending",
        documentType: "drivers_license",
        submittedAt: new Date(),
      })
    );
  });

  test("create rejected when status is not pending", async () => {
    const ctx = getAuthContext("user1");
    await assertFails(
      ctx.firestore().doc("identity_verification/user1").set({
        uid: "user1",
        idPhotoUrl: "https://example.com/id.jpg",
        selfieUrl: "https://example.com/selfie.jpg",
        status: "approved",
      })
    );
  });

  test("user can resubmit (update to pending)", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("identity_verification/user1").set({
        uid: "user1",
        idPhotoUrl: "https://example.com/id.jpg",
        selfieUrl: "https://example.com/selfie.jpg",
        status: "rejected",
        rejectionReason: "blurry photo",
      });
    });

    const ctx = getAuthContext("user1");
    await assertSucceeds(
      ctx.firestore().doc("identity_verification/user1").update({
        idPhotoUrl: "https://example.com/id2.jpg",
        selfieUrl: "https://example.com/selfie2.jpg",
        status: "pending",
      })
    );
  });

  test("admin can approve", async () => {
    await setupAdmin("admin1");
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("identity_verification/user1").set({
        uid: "user1",
        idPhotoUrl: "https://example.com/id.jpg",
        selfieUrl: "https://example.com/selfie.jpg",
        status: "pending",
      });
    });

    const ctx = getAuthContext("admin1");
    await assertSucceeds(
      ctx.firestore().doc("identity_verification/user1").update({
        status: "approved",
        reviewedBy: "admin1",
        reviewedAt: new Date(),
      })
    );
  });

  test("admin can reject", async () => {
    await setupAdmin("admin1");
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("identity_verification/user1").set({
        uid: "user1",
        idPhotoUrl: "https://example.com/id.jpg",
        selfieUrl: "https://example.com/selfie.jpg",
        status: "pending",
      });
    });

    const ctx = getAuthContext("admin1");
    await assertSucceeds(
      ctx.firestore().doc("identity_verification/user1").update({
        status: "rejected",
        reviewedBy: "admin1",
        rejectionReason: "blurry photo",
      })
    );
  });

  test("other user cannot access document", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc("identity_verification/user1").set({
        uid: "user1",
        idPhotoUrl: "https://example.com/id.jpg",
        selfieUrl: "https://example.com/selfie.jpg",
        status: "pending",
      });
    });

    const ctx = getAuthContext("user2");
    await assertFails(
      ctx.firestore().doc("identity_verification/user1").get()
    );
  });
});
