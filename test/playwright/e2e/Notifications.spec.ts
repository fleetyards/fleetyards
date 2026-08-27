import { app, appScenario } from "../support/on-rails";
import { test, expect } from "../support/commands";

const row = (page: import("@playwright/test").Page, title: string) =>
  page.getByTestId("notification-item").filter({ hasText: title });

test.describe("Notifications", () => {
  test.beforeEach(async ({ page }) => {
    // Against a dev vite server the first visit compiles the route's module
    // graph, which on its own can outrun the default timeout.
    test.slow();

    await app("clean");
    await appScenario("notifications");

    await page.goto("/login/", { waitUntil: "domcontentloaded" });
    await page.locator("input[name='login']").fill("notifications");
    await page.locator("input[name='password']").fill("password123");

    const sessionCreated = page.waitForResponse(
      (response) =>
        response.url().includes("/api/v1/sessions") &&
        response.request().method() === "POST",
    );

    await page.getByTestId("submit-login").click();

    await sessionCreated;

    await expect(page).not.toHaveURL(/\/login/);

    await page.goto("/notifications/", { waitUntil: "domcontentloaded" });

    await expect(page.getByTestId("notification-item").first()).toBeVisible({
      timeout: 60000,
    });
  });

  test("Lists the inbox with an empty reading pane", async ({ page }) => {
    await expect(page.getByTestId("notification-item")).toHaveCount(6);
    await expect(page.getByTestId("notification-detail-empty")).toBeVisible();
  });

  test("Opens a notification in the reading pane with one click", async ({
    page,
  }) => {
    await row(page, "Hangar sync failed")
      .getByTestId("notification-select")
      .click();

    await expect(page.getByTestId("notification-detail-title")).toContainText(
      "Hangar sync failed",
    );
    await expect(page.getByTestId("notification-detail-body")).toContainText(
      "Ships imported",
    );
  });

  test("Marks a notification as read by opening it", async ({ page }) => {
    const unread = row(page, "Hangar sync failed");

    await expect(unread).toHaveClass(/notification-item--unread/);

    await unread.getByTestId("notification-select").click();

    await expect(unread).not.toHaveClass(/notification-item--unread/);
  });

  test("Keeps the opened notification in place instead of resorting", async ({
    page,
  }) => {
    const first = page.getByTestId("notification-item").first();

    await first.getByTestId("notification-select").click();

    await expect(first).toContainText("You were invited to Test Fleet");
  });

  test("Moves through the list with the arrow keys", async ({ page }) => {
    await page
      .getByTestId("notification-item")
      .first()
      .getByTestId("notification-select")
      .click();

    await expect(page.getByTestId("notification-detail-title")).toContainText(
      "You were invited to Test Fleet",
    );

    await page.keyboard.press("ArrowDown");

    await expect(page.getByTestId("notification-detail-title")).toContainText(
      "Hangar sync failed",
    );

    await page.keyboard.press("ArrowUp");

    await expect(page.getByTestId("notification-detail-title")).toContainText(
      "You were invited to Test Fleet",
    );
  });

  test("Marks an opened notification unread again", async ({ page }) => {
    const target = row(page, "Hangar sync failed");

    await target.getByTestId("notification-select").click();

    await expect(target).not.toHaveClass(/notification-item--unread/);

    await page.getByTestId("notification-detail-unread").click();

    await expect(target).toHaveClass(/notification-item--unread/);
  });

  test("Archives a notification out of the inbox and into the archive", async ({
    page,
    notification,
  }) => {
    await row(page, "Aurora MR added to your hangar")
      .getByLabel("Archive", { exact: true })
      .click();

    await notification.success("Notification archived");

    await expect(row(page, "Aurora MR added to your hangar")).toHaveCount(0);

    await page.getByTestId("notifications-tab-archive").click();

    await expect(row(page, "Aurora MR added to your hangar")).toHaveCount(1);
  });

  test("Moves an archived notification back to the inbox", async ({
    page,
    notification,
  }) => {
    await page.getByTestId("notifications-tab-archive").click();

    await expect(row(page, "Hangar sync finished")).toHaveCount(1);

    await row(page, "Hangar sync finished")
      .getByLabel("Move back to inbox", { exact: true })
      .click();

    // Dismissed rather than waited out: a toast left standing covers the tabs.
    await notification.success("Notification moved back to the inbox");

    await expect(row(page, "Hangar sync finished")).toHaveCount(0);

    await page.getByTestId("notifications-tab-inbox").click();

    await expect(row(page, "Hangar sync finished")).toHaveCount(1);
  });

  test("Shows a placeholder for a notification without a body", async ({
    page,
  }) => {
    await row(page, "Aurora MR added to your hangar")
      .getByTestId("notification-select")
      .click();

    await expect(page.getByTestId("notification-detail-title")).toContainText(
      "Aurora MR added to your hangar",
    );
    await expect(page.getByTestId("notification-detail-no-body")).toBeVisible();
  });

  test("Counts the unread notifications in the navigation", async ({
    page,
  }) => {
    await expect(page.getByTestId("nav-notifications")).toContainText("4");

    await row(page, "Hangar sync failed")
      .getByTestId("notification-select")
      .click();

    await expect(page.getByTestId("nav-notifications")).toContainText("3");
  });
});
