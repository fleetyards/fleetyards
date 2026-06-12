import { test, expect } from "../support/commands";
import { app, appScenario } from "../support/on-rails";

test.describe("Home", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean");
    await appScenario("ships");

    await page.goto("/");
  });

  test("Loads", async ({ page }) => {
    await expect(page.getByText("Welcome")).toBeVisible();
  });

  test("Shows Search Results via Button", async ({ page }) => {
    await page.fill('[data-test="input-search"]', "Iron");
    await page.click("#search-submit");

    await expect(page).toHaveURL(/.*\/ships/);
    await expect(
      page.getByTestId("panel-heading-title").locator("span").getByText("Ironclad"),
    ).toBeVisible();
  });

  test("Shows Search Results via Key", async ({ page }) => {
    await page.fill('[data-test="input-search"]', "Corsair");
    await page.keyboard.press("Enter");

    await expect(page).toHaveURL(/.*\/ships/);
    await expect(
      page.getByTestId("panel-heading-title").locator("span").getByText("Corsair"),
    ).toBeVisible();
  });

  test("Shows Latest Ships", async ({ page }) => {
    const ships = page.getByTestId("home-ships").locator(".panel");
    await expect(ships).toHaveCount(2);
  });

  test("Shows Random Images", async ({ page }) => {
    const images = page.getByTestId("home-images").getByTestId("home-image");
    await expect(images).toHaveCount(10);
  });
});
