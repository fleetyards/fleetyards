import { app, appScenario } from "../support/on-rails";
import { test, expect } from "../support/commands";

const row = (page: import("@playwright/test").Page, title: string) =>
  page.getByTestId("notification-item").filter({ hasText: title });

test.describe("Admin Notifications", () => {
  test.beforeEach(async ({ page }) => {
    // Against a dev vite server the first visit compiles the route's module
    // graph, which on its own can outrun the default timeout.
    test.slow();

    await app("clean");
    await appScenario("admin_notifications");

    await page.goto("/admin/login/", { waitUntil: "domcontentloaded" });
    await page.locator("input[name='login']").fill("admin_notifications");
    await page.locator("input[name='password']").fill("password123");
    await page.getByTestId("submit-login").click();

    await expect(page).toHaveURL(/\/admin\/?$/);

    // The URL turns over before the app has the session; navigating on top of
    // that lands back on the login form.
    await page.waitForLoadState("networkidle");

    await page.goto("/admin/notifications/", { waitUntil: "domcontentloaded" });

    await expect(page.getByTestId("notification-item").first()).toBeVisible({
      timeout: 60000,
    });
  });

  test("Lists the notifications with an empty reading pane", async ({
    page,
  }) => {
    await expect(page.getByTestId("notification-item")).toHaveCount(9);
    await expect(page.getByTestId("notification-detail-empty")).toBeVisible();
  });

  test("Opens a notification in the reading pane with one click", async ({
    page,
  }) => {
    await row(page, "Modules Import Results")
      .getByTestId("notification-select")
      .click();

    await expect(page.getByTestId("notification-detail-title")).toContainText(
      "Modules Import Results",
    );
    await expect(page.getByTestId("notification-detail-body")).toContainText(
      "Retaliator Bomber",
    );
  });

  test("Marks a notification as read by opening it", async ({ page }) => {
    const unread = row(page, "Modules Import Results");

    await expect(unread).toHaveClass(/notification-item--unread/);

    await unread.getByTestId("notification-select").click();

    await expect(unread).not.toHaveClass(/notification-item--unread/);
  });

  test("Keeps the opened notification in place instead of resorting", async ({
    page,
  }) => {
    const first = page.getByTestId("notification-item").first();

    await first.getByTestId("notification-select").click();

    await expect(first).toContainText("RSI blocked a request");
  });

  test("Moves through the list with the arrow keys", async ({ page }) => {
    await page
      .getByTestId("notification-item")
      .first()
      .getByTestId("notification-select")
      .click();

    await expect(page.getByTestId("notification-detail-title")).toContainText(
      "RSI blocked a request",
    );

    await page.keyboard.press("ArrowDown");

    await expect(page.getByTestId("notification-detail-title")).toContainText(
      "Modules Import Results",
    );

    await page.keyboard.press("ArrowUp");

    await expect(page.getByTestId("notification-detail-title")).toContainText(
      "RSI blocked a request",
    );
  });

  test("Marks an opened notification unread again", async ({ page }) => {
    const target = row(page, "Modules Import Results");

    await target.getByTestId("notification-select").click();

    await expect(target).not.toHaveClass(/notification-item--unread/);

    await page.getByTestId("notification-detail-unread").click();

    await expect(target).toHaveClass(/notification-item--unread/);
  });

  test("Archives a notification out of the inbox and into the archive", async ({
    page,
    notification,
  }) => {
    await row(page, "Loaner Sync finished")
      .getByLabel("Archive", { exact: true })
      .click();

    await notification.success("Notification archived");

    await expect(row(page, "Loaner Sync finished")).toHaveCount(0);

    await page.getByTestId("notifications-tab-archive").click();

    await expect(row(page, "Loaner Sync finished")).toHaveCount(1);
  });

  test("Moves an archived notification back to the inbox", async ({
    page,
    notification,
  }) => {
    await row(page, "Loaner Sync finished")
      .getByLabel("Archive", { exact: true })
      .click();

    // Dismissed rather than waited out: a toast left standing covers the tabs.
    await notification.success("Notification archived");

    await page.getByTestId("notifications-tab-archive").click();

    await row(page, "Loaner Sync finished")
      .getByLabel("Move back to inbox", { exact: true })
      .click();

    await notification.success("Notification moved back to the inbox");

    await expect(row(page, "Loaner Sync finished")).toHaveCount(0);

    await page.getByTestId("notifications-tab-inbox").click();

    await expect(row(page, "Loaner Sync finished")).toHaveCount(1);
  });

  test("Shows a placeholder for a notification without a body", async ({
    page,
  }) => {
    await row(page, "Loaner Sync finished")
      .getByTestId("notification-select")
      .click();

    await expect(page.getByTestId("notification-detail-title")).toContainText(
      "Loaner Sync finished",
    );
    await expect(page.getByTestId("notification-detail-no-body")).toBeVisible();
  });
});
