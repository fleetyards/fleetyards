import { test, expect } from "../support/commands";
import { app, appScenario } from "../support/on-rails";

test.describe("Home", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean");
    await appScenario("ships");

    await page.goto("/");
  });

  test("Loads", async ({ page }) => {
    await expect(page.getByTestId("home-landing")).toBeVisible();
  });

  test("Opens the highlighted search result via Key", async ({ page }) => {
    await page.fill('[data-test="input-search"]', "Iron");

    await expect(
      page.getByTestId("home-search-result").getByText("Ironclad"),
    ).toBeVisible();

    await page.keyboard.press("Enter");

    await expect(page).toHaveURL(/.*\/ships\/ironclad/);
  });

  test("Shows Latest Ships", async ({ page }) => {
    const ships = page
      .getByTestId("home-landing-latest-ships")
      .locator(".panel");
    await expect(ships.first()).toBeVisible();
  });
});
