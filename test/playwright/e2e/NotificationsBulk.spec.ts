import { app, appScenario } from "../support/on-rails";
import { test, expect } from "../support/commands";

const row = (page: import("@playwright/test").Page, title: string) =>
  page.getByTestId("notification-item").filter({ hasText: title });

// The scenario fills one page and a bit: 25 rows are shown, 30 exist.
const PER_PAGE = 25;
const TOTAL = 30;

test.describe("Notifications bulk operations", () => {
  test.beforeEach(async ({ page }) => {
    // Against a dev vite server the first visit compiles the route's module
    // graph, which on its own can outrun the default timeout.
    test.slow();

    await app("clean");
    await appScenario("notifications_bulk");

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

  // Hidden rather than absent: the bar keeps its height so ticking a row does
  // not push the list down.
  test("Offers no actions until something is ticked", async ({ page }) => {
    await expect(page.getByTestId("bulk-selection-bar")).toBeVisible();
    await expect(page.getByTestId("bulk-selection-count")).toBeHidden();
    await expect(page.getByTestId("bulk-archive")).toBeHidden();

    const idle = await page.getByTestId("bulk-selection-bar").boundingBox();

    await page.getByTestId("bulk-select-page").click();

    await expect(page.getByTestId("bulk-selection-count")).toBeVisible();

    const selected = await page.getByTestId("bulk-selection-bar").boundingBox();

    expect(selected?.height).toBe(idle?.height);
  });

  test("Archives the rows ticked one by one", async ({ page, notification }) => {
    await row(page, "Bulk notification 01")
      .getByTestId("notification-checkbox")
      .click();
    await row(page, "Bulk notification 02")
      .getByTestId("notification-checkbox")
      .click();

    await expect(page.getByTestId("bulk-selection-count")).toContainText(
      "2 selected",
    );

    await page.getByTestId("bulk-archive").click();

    await notification.success("2 notifications archived");

    await expect(row(page, "Bulk notification 01")).toHaveCount(0);
    await expect(row(page, "Bulk notification 02")).toHaveCount(0);

    await page.getByTestId("notifications-tab-archive").click();

    await expect(row(page, "Bulk notification 01")).toHaveCount(1);
  });

  test("Ticks the whole page from the header checkbox", async ({ page }) => {
    await page.getByTestId("bulk-select-page").click();

    await expect(page.getByTestId("bulk-selection-count")).toContainText(
      `${PER_PAGE} selected`,
    );
    await expect(page.getByTestId("notification-item")).toHaveCount(PER_PAGE);
  });

  test("Reaches past the page with select all", async ({
    page,
    notification,
  }) => {
    await page.getByTestId("bulk-select-page").click();

    // Only on offer once the page is full and there is more behind it.
    await page.getByTestId("bulk-select-all-matching").click();

    await expect(page.getByTestId("bulk-selection-count")).toContainText(
      `All ${TOTAL} selected`,
    );

    await page.getByTestId("bulk-read").click();

    await notification.success(`${TOTAL} notifications marked as read`);

    // Nothing unread left anywhere, not just on the page that was shown.
    await expect(page.locator(".notification-item--unread")).toHaveCount(0);
  });

  test("Drops the selection when the reader leaves the tab", async ({
    page,
  }) => {
    await page.getByTestId("bulk-select-page").click();

    await expect(page.getByTestId("bulk-selection-count")).toBeVisible();

    await page.getByTestId("notifications-tab-archive").click();

    await expect(row(page, "Archived notification 01")).toHaveCount(1);
    await expect(page.getByTestId("bulk-selection-count")).toBeHidden();
  });

  test("Deletes the selected rows after confirming", async ({
    page,
    notification,
  }) => {
    await row(page, "Bulk notification 01")
      .getByTestId("notification-checkbox")
      .click();

    await page.getByTestId("bulk-destroy").click();
    await page.getByTestId("confirm-ok").click();

    await notification.success("1 notification deleted");

    await expect(row(page, "Bulk notification 01")).toHaveCount(0);
  });
});
