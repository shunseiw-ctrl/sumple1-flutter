describe("stripeTestHelper", () => {
  test("module loads without error", () => {
    const mod = require("../src/stripeTestHelper");
    expect(mod.simulateStripeWebhook).toBeDefined();
  });

  test("simulateStripeWebhook is a callable function", () => {
    const mod = require("../src/stripeTestHelper");
    expect(typeof mod.simulateStripeWebhook).toBe("function");
  });
});
