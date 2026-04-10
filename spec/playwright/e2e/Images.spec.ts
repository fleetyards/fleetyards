import { test, expect } from "../support/commands";
import { app, appScenario } from "../support/on-rails";

test.describe("Images", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean");
    await appScenario("images");

    await page.goto("/");
  });

  test("Loads", async ({ page, nav }) => {
    await nav.click("images");

    await expect(page).toHaveURL(/\/images/);

    const images = page.getByTestId("images-list").locator("a");
    await expect(images).toHaveCount(20);
  });
});
