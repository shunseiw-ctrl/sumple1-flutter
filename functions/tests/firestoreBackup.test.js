const admin = require("firebase-admin");

// firebase-admin のモック
jest.mock("firebase-admin", () => {
  const firestoreMock = {
    collection: jest.fn(),
  };

  const mockExportDocuments = jest.fn();
  const mockDatabasePath = jest.fn();

  const firestoreNamespace = jest.fn(() => firestoreMock);
  firestoreNamespace.v1 = {
    FirestoreAdminClient: jest.fn().mockImplementation(() => ({
      exportDocuments: mockExportDocuments,
      databasePath: mockDatabasePath,
    })),
  };
  firestoreNamespace.FieldValue = {
    serverTimestamp: jest.fn(() => "SERVER_TIMESTAMP"),
  };

  return {
    initializeApp: jest.fn(),
    firestore: firestoreNamespace,
  };
});

const { BACKUP_COLLECTIONS } = require("../src/firestoreBackup");

describe("firestoreBackup", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test("BACKUP_COLLECTIONSに必要なコレクションが含まれる", () => {
    expect(BACKUP_COLLECTIONS).toContain("profiles");
    expect(BACKUP_COLLECTIONS).toContain("jobs");
    expect(BACKUP_COLLECTIONS).toContain("applications");
    expect(BACKUP_COLLECTIONS).toContain("earnings");
    expect(BACKUP_COLLECTIONS).toContain("payments");
    expect(BACKUP_COLLECTIONS).toContain("ratings");
    expect(BACKUP_COLLECTIONS).toContain("chats");
    expect(BACKUP_COLLECTIONS).toContain("notifications");
    expect(BACKUP_COLLECTIONS).toContain("contacts");
    expect(BACKUP_COLLECTIONS).toContain("config");
    expect(BACKUP_COLLECTIONS).toContain("audit_logs");
    expect(BACKUP_COLLECTIONS).toContain("favorites");
    expect(BACKUP_COLLECTIONS).toHaveLength(12);
  });

  test("exportDocumentsが正しいパラメータで呼ばれる", () => {
    // FirestoreAdminClient のモックを検証
    const client = new admin.firestore.v1.FirestoreAdminClient();

    client.databasePath.mockReturnValue(
      "projects/test-project/databases/(default)",
    );

    client.exportDocuments.mockResolvedValue([
      { name: "operations/test-op-123" },
    ]);

    // exportDocuments を呼び出し
    const result = client.exportDocuments({
      name: "projects/test-project/databases/(default)",
      outputUriPrefix: "gs://test-project-firestore-backups/2026-03-02",
      collectionIds: BACKUP_COLLECTIONS,
    });

    expect(client.exportDocuments).toHaveBeenCalledWith({
      name: "projects/test-project/databases/(default)",
      outputUriPrefix: "gs://test-project-firestore-backups/2026-03-02",
      collectionIds: BACKUP_COLLECTIONS,
    });

    expect(result).toBeTruthy();
  });
});
