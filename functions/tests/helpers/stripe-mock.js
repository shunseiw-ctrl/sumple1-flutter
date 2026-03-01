// Stripe API モック
function createStripeMock(overrides = {}) {
  return {
    accounts: {
      create: jest.fn().mockResolvedValue({
        id: "acct_test_123",
        charges_enabled: false,
        payouts_enabled: false,
        details_submitted: false,
      }),
      retrieve: jest.fn().mockResolvedValue({
        id: "acct_test_123",
        charges_enabled: true,
        payouts_enabled: true,
        details_submitted: true,
      }),
      createLoginLink: jest.fn().mockResolvedValue({
        url: "https://connect.stripe.com/express/login",
      }),
      ...overrides.accounts,
    },
    accountLinks: {
      create: jest.fn().mockResolvedValue({
        url: "https://connect.stripe.com/setup/test",
      }),
      ...overrides.accountLinks,
    },
    paymentIntents: {
      create: jest.fn().mockResolvedValue({
        id: "pi_test_123",
        client_secret: "pi_test_123_secret",
        status: "requires_payment_method",
      }),
      ...overrides.paymentIntents,
    },
    webhooks: {
      constructEvent: jest.fn().mockImplementation((body, sig, secret) => {
        if (!sig || sig === "invalid") {
          throw new Error("Invalid signature");
        }
        return JSON.parse(body);
      }),
      ...overrides.webhooks,
    },
  };
}

module.exports = { createStripeMock };
