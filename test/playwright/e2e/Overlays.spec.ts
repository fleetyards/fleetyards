import { test, expect } from "../support/commands";

/*
 * AppConfirm and OffCanvas are singletons mounted in App.vue and driven by
 * comlink events, so they are only ever on screen mid-action - the confirm
 * during a destructive click, and the off-canvas on mobile, where FilteredList
 * is the only thing that opens it. The demo page asks for both directly, which
 * is what makes them testable at desktop width at all.
 */

test.describe("Overlays", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/visual-tests/overlays/");
    await expect(page.locator(".visual-tests")).toBeVisible();
  });

  test("the confirm runs its handler and closes", async ({ page }) => {
    await page.getByTestId("confirm-default").click();

    const confirm = page.locator(".app-confirm, [class*='confirm']").first();
    await expect(confirm).toBeVisible();

    await page.getByText("Confirm", { exact: true }).click();

    await expect(page.getByText("confirmed (default text)")).toBeVisible();
  });

  test("escape cancels the confirm", async ({ page }) => {
    // Keyboard is the half no screenshot covers: Enter confirms, Escape cancels.
    await page.getByTestId("confirm-custom").click();
    await expect(page.getByText("Delete it")).toBeVisible();

    await page.keyboard.press("Escape");

    await expect(page.getByText("cancelled (custom text)")).toBeVisible();
    await expect(page.getByText("Delete it")).toHaveCount(0);
  });

  test("enter confirms the confirm", async ({ page }) => {
    await page.getByTestId("confirm-default").click();
    await expect(page.getByText("Confirm", { exact: true })).toBeVisible();

    await page.keyboard.press("Enter");

    await expect(page.getByText("confirmed (default text)")).toBeVisible();
  });

  test("the off-canvas opens on either side and closes", async ({ page }) => {
    const panel = page.locator(".off-canvas__panel");
    const content = page.getByTestId("off-canvas-demo-content");

    // Teleported once and left there, so it exists before the panel opens.
    await expect(content).toHaveCount(1);

    await page.getByTestId("off-canvas-left").click();
    await expect(panel).toBeVisible();
    await expect(page.getByText("Filters")).toBeVisible();

    await page.getByTestId("off-canvas-inner-close").click();
    await expect(page.locator(".off-canvas__backdrop")).toHaveCount(0);

    await page.getByTestId("off-canvas-right").click();
    await expect(panel).toBeVisible();
    await expect(page.getByText("Details")).toBeVisible();
  });

  test("a crumb without a target is not a link", async ({ page }) => {
    const crumbs = page.locator(".bread-crumbs, [class*='crumb']").first();
    await expect(crumbs).toBeVisible();

    // The last crumb is the current page, so it must not be clickable.
    const last = crumbs.locator("li").last();
    await expect(last.locator("a")).toHaveCount(0);
  });
});
