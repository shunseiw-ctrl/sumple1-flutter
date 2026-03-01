const firebaseFunctionsTest = require("firebase-functions-test");

// オフラインモードで初期化（実際のFirebaseプロジェクトに接続しない）
const testEnv = firebaseFunctionsTest();

// Firestore モックヘルパー
function createMockFirestoreSnapshot(data, id = "test-doc-id") {
  return {
    data: () => data,
    id,
    exists: data !== null && data !== undefined,
    ref: {
      id,
      update: jest.fn().mockResolvedValue(undefined),
      set: jest.fn().mockResolvedValue(undefined),
    },
  };
}

function createMockFirestoreEvent(data, params = {}) {
  const snap = data ? createMockFirestoreSnapshot(data, params.docId || "test-doc-id") : null;
  return {
    data: snap,
    params,
  };
}

module.exports = {
  testEnv,
  createMockFirestoreSnapshot,
  createMockFirestoreEvent,
};
