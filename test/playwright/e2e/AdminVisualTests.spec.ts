import { app, appScenario } from "../support/on-rails";
import { test, expect } from "../support/commands";

/*
 * The admin area had no gallery at all - 76 components and nowhere to look at
 * them. This is the first page of one, for the notification centre, whose list
 * row and reading pane are pure props and so show every state without the data
 * having to be in the database.
 *
 * It needs a login and only a login: the gallery sits behind the admin guard
 * like every other admin route, because on stage that area is real. The scenario
 * is here for the admin user, not for its notifications - the page uses
 * fixtures.
 */
test.describe("Admin visual tests", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean");
    await appScenario("admin_notifications");

    await page.goto("/admin/login/");
    await page.locator("input[name='login']").fill("admin_notifications");
    await page.locator("input[name='password']").fill("password123");
    await page.getByTestId("submit-login").click();
    await expect(page).toHaveURL(/\/admin\/?$/);

    await page.goto("/admin/visual-tests/notifications/");
    await expect(page.locator(".visual-tests")).toBeVisible();
  });

  test("shows every severity, and none on info", async ({ page }) => {
    // A label on every row would say nothing, so info carries no pill.
    const rows = page.locator("[data-test='severities'] > *");
    await expect(rows).toHaveCount(4);

    const pills = await page
      .locator("[data-test='severities']")
      .evaluate((el) =>
        [...el.children].map(
          (row) =>
            row.querySelector("[data-test='pill']")?.textContent?.trim() ??
            null,
        ),
      );

    expect(pills[0], "info carries no pill").toBeNull();
    expect(pills[1]).toBeTruthy();
    expect(pills[2]).toBeTruthy();
  });

  test("the reading pane has an empty state", async ({ page }) => {
    // What the pane shows for most of the time the page is open, and the state
    // hardest to reach on the real page.
    await expect(
      page.getByTestId("notification-detail-empty").first(),
    ).toBeVisible();
  });

  test("selecting in the list changes the pane", async ({ page }) => {
    const list = page.locator("[data-test='wired-list']");
    const rows = list.locator("> *");
    await expect(rows).toHaveCount(7);

    await rows.nth(2).click();

    // The wired pair is the only place the two halves are seen together.
    await expect(page.getByTestId("wired-detail")).toContainText("RSI API");
  });

  test("the page does not scroll sideways on a phone", async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 900 });

    const doc = await page.evaluate(() => ({
      scroll: document.documentElement.scrollWidth,
      client: document.documentElement.clientWidth,
    }));

    expect(doc.scroll, JSON.stringify(doc)).toBeLessThanOrEqual(doc.client + 1);
  });
});
