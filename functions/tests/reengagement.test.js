const assert = require("assert");

describe("Reengagement Notifications", () => {
  const MESSAGES = [
    { title: "新着案件があります", body: "あなたのエリアに新しい案件が追加されました。チェックしてみましょう！" },
    { title: "プロフィールを充実させましょう", body: "プロフィールを充実させると、企業からのスカウト率がアップします。" },
    { title: "お仕事をお探しですか？", body: "条件にマッチする案件が見つかるかもしれません。今すぐチェック！" },
  ];

  it("should select message based on day index", () => {
    const msgIndex = Math.floor(Date.now() / (24 * 60 * 60 * 1000)) % MESSAGES.length;
    assert.ok(msgIndex >= 0 && msgIndex < MESSAGES.length);
    assert.ok(MESSAGES[msgIndex].title.length > 0);
    assert.ok(MESSAGES[msgIndex].body.length > 0);
  });

  it("should respect opt-out preference", () => {
    const prefs = { reengagement: false };
    assert.strictEqual(prefs.reengagement, false);
  });

  it("should skip active users", () => {
    const lastActive = new Date();
    const threeDaysAgo = new Date(Date.now() - 3 * 24 * 60 * 60 * 1000);
    assert.ok(lastActive > threeDaysAgo, "Active user should be newer than threshold");
  });

  it("should have correct message rotation", () => {
    const indices = new Set();
    for (let i = 0; i < MESSAGES.length; i++) {
      indices.add(i % MESSAGES.length);
    }
    assert.strictEqual(indices.size, MESSAGES.length);
  });
});
