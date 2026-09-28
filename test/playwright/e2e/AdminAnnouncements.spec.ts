import { app, appScenario } from "../support/on-rails";
import { test, expect } from "../support/commands";

test.describe("Admin Announcements", () => {
  test.beforeEach(async ({ page }) => {
    // Against a dev vite server the first visit compiles the route's module
    // graph, which on its own can outrun the default timeout.
    test.slow();

    await app("clean");
    await appScenario("admin_announcements");

    await page.goto("/admin/login/", { waitUntil: "domcontentloaded" });
    await page.locator("input[name='login']").fill("admin_announcements");
    await page.locator("input[name='password']").fill("password123");
    await page.getByTestId("submit-login").click();

    await expect(page).toHaveURL(/\/admin\/?$/);

    // The URL turns over before the app has the session; navigating on top of
    // that lands back on the login form.
    await page.waitForLoadState("networkidle");

    await page.goto("/admin/announcements/", { waitUntil: "domcontentloaded" });

    await expect(page.getByTestId("announcement-row").first()).toBeVisible({
      timeout: 60000,
    });
  });

  test("Summarises each row's deliveries", async ({ page }) => {
    const sent = page
      .getByTestId("announcement-row")
      .filter({ hasText: "Trade routes for your ship" });

    await expect(sent.getByTestId("announcement-delivery-summary")).toHaveText(
      "3/4 sent · 1 failed",
    );
    await expect(sent.getByTestId("announcement-deliveries")).toHaveCount(0);

    const draft = page
      .getByTestId("announcement-row")
      .filter({ hasText: "Draft for next week" });

    await expect(
      draft.getByTestId("announcement-delivery-summary"),
    ).toHaveCount(0);
  });

  test("Shows each channel's delivery and engagement on the detail page", async ({
    page,
  }) => {
    await page
      .getByRole("link", { name: "Trade routes for your ship" })
      .click();

    await expect(page).toHaveURL(/\/admin\/announcements\/[0-9a-f-]+\/$/);

    const deliveries = page.getByTestId("announcement-deliveries-panel");

    await expect(
      deliveries.getByTestId("announcement-engagement-likes"),
    ).toContainText("42");
    await expect(
      deliveries.getByTestId("announcement-engagement-reaction"),
    ).toHaveText(["🚀14", "👍6"]);
    await expect(
      deliveries.getByTestId("announcement-delivery-retry"),
    ).toHaveCount(1);
    // Rows sort by channel, and the failed X post has nothing to open.
    await expect(
      deliveries.getByTestId("announcement-delivery-link"),
    ).toHaveCount(2);
    await expect(
      deliveries.getByTestId("announcement-delivery-link").first(),
    ).toHaveAttribute(
      "href",
      "https://bsky.app/profile/did:plc:fleetyards/post/3k",
    );
    await expect(
      deliveries.getByTestId("announcement-delivery-link").last(),
    ).toHaveAttribute("href", "https://discord.com/channels/333/222/111");
    await expect(
      deliveries.getByTestId("announcement-refresh-engagement"),
    ).toBeVisible();
  });
});
