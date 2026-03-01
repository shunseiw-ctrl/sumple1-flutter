module.exports = {
  env: {
    es2022: true,
    node: true,
    jest: true,
  },
  extends: ["eslint:recommended", "google"],
  parserOptions: {
    ecmaVersion: 2022,
  },
  rules: {
    "quotes": ["error", "double", { allowTemplateLiterals: true }],
    "max-len": ["warn", { code: 120 }],
    "require-jsdoc": "off",
    "object-curly-spacing": "off",
    "indent": ["error", 2],
    "comma-dangle": ["error", "always-multiline"],
    "no-unused-vars": ["warn", { argsIgnorePattern: "^_" }],
  },
};
