import { test, expect } from "../support/commands";

test.describe("Install prompt", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/visual-tests/install-prompt/");
    await expect(page.locator(".visual-tests")).toBeVisible();
  });

  test("the offer installs or steps aside", async ({ page }) => {
    await page.getByTestId("trigger-install-hint").click();

    await expect(page.getByTestId("install-app-hint-cta")).toBeVisible();

    await page.getByTestId("install-app-hint-later").click();

    await expect(page.getByTestId("install-app-hint-cta")).toHaveCount(0);
  });

  test("iOS gets the share-sheet steps", async ({ page }) => {
    await page.getByTestId("open-ios-instructions").click();

    await expect(
      page.getByTestId("install-app-ios-steps").locator("li"),
    ).toHaveCount(3);
  });
});
