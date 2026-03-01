module.exports = {
  testMatch: ["**/tests/**/*.test.js"],
  collectCoverageFrom: [
    "src/**/*.js",
    "index.js",
    "!**/node_modules/**",
  ],
  coverageDirectory: "coverage",
  testEnvironment: "node",
};
