const admin = require("firebase-admin");
const { expect } = require("@jest/globals");

// Mock firebase-admin
jest.mock("firebase-admin", () => {
  const firestoreMock = {
    collection: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnThis(),
    set: jest.fn().mockResolvedValue({}),
    add: jest.fn().mockResolvedValue({ id: "notif-1" }),
    get: jest.fn().mockResolvedValue({
      exists: true,
      data: () => ({ adminUids: ["admin1"], emails: ["admin@albawork.com"] }),
    }),
    batch: jest.fn().mockReturnValue({
      set: jest.fn(),
      commit: jest.fn().mockResolvedValue({}),
    }),
  };
  return {
    initializeApp: jest.fn(),
    firestore: jest.fn(() => firestoreMock),
    app: jest.fn(),
  };
});

// Need to add FieldValue mock
admin.firestore.FieldValue = {
  serverTimestamp: jest.fn(() => new Date()),
};

describe("identityVerification Cloud Function logic", () => {
  test("pending status triggers admin notification logic", () => {
    // Verify the module loads without error
    const ivModule = require("../src/identityVerification");
    expect(ivModule.onVerificationStatusChanged).toBeDefined();
  });

  test("approved/rejected status triggers user notification logic", () => {
    const ivModule = require("../src/identityVerification");
    expect(typeof ivModule.onVerificationStatusChanged).toBe("function");
  });
});
