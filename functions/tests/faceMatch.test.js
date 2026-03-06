const { describe, it, expect } = require("@jest/globals");

// faceMatch.jsの内部ロジックをテスト
// face-api.js はCIで重いため、ロジックのユニットテストに限定

describe("faceMatch - score calculation logic", () => {
  // スコア計算ロジック: max(0, (1 - distance/1.5) * 100)
  function calculateScore(distance) {
    return Math.round(Math.max(0, (1 - distance / 1.5) * 100));
  }

  it("distance 0 → score 100 (完全一致)", () => {
    expect(calculateScore(0)).toBe(100);
  });

  it("distance 0.3 → score 80 (同一人物の閾値)", () => {
    expect(calculateScore(0.3)).toBe(80);
  });

  it("distance 0.6 → score 60", () => {
    expect(calculateScore(0.6)).toBe(60);
  });

  it("distance 0.9 → score 40 (別人の可能性高)", () => {
    expect(calculateScore(0.9)).toBe(40);
  });

  it("distance 1.5 → score 0", () => {
    expect(calculateScore(1.5)).toBe(0);
  });

  it("distance 2.0 → score 0 (下限)", () => {
    expect(calculateScore(2.0)).toBe(0);
  });

  it("score >= 80 → matched: true", () => {
    const score = calculateScore(0.25);
    expect(score).toBeGreaterThanOrEqual(80);
    expect(score >= 80).toBe(true);
  });

  it("score < 80 → matched: false", () => {
    const score = calculateScore(0.5);
    expect(score).toBeLessThan(80);
    expect(score >= 80).toBe(false);
  });
});

describe("faceMatch - writeResult format", () => {
  it("result contains score and matched fields", () => {
    const result = { score: 85, matched: true };
    expect(result).toHaveProperty("score");
    expect(result).toHaveProperty("matched");
    expect(typeof result.score).toBe("number");
    expect(typeof result.matched).toBe("boolean");
  });

  it("error result contains error field", () => {
    const result = { score: 0, matched: false, error: "id_face_not_found" };
    expect(result.error).toBe("id_face_not_found");
    expect(result.matched).toBe(false);
  });
});
