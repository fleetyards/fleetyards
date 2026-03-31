import { app, appScenario } from "../support/on-rails";
import { test, expect } from "../support/commands";

test.describe("Travel Times", () => {
  test.beforeEach(async ({ page, acceptCookie }) => {
    await app("clean");
    await appScenario("tools");

    await page.goto("/tools/travel-times/");

    await acceptCookie.accept();
  });

  test("Loads the page", async ({ page }) => {
    await expect(page).toHaveURL(/\/tools\/travel-times/);
    await expect(page.locator("h1")).toBeVisible();
  });

  test("Shows distance input with default value", async ({ page }) => {
    const distanceInput = page.locator('input[name="distance"]');
    await expect(distanceInput).toBeVisible();
    await expect(distanceInput).toHaveValue("20");
  });

  test("Shows quantum drives list", async ({ page }) => {
    // Wait for quantum drives to load
    await expect(page.getByText("Beacon")).toBeVisible();
    await expect(page.getByText("Expedition")).toBeVisible();
  });

  test("Updates travel times when distance changes", async ({ page }) => {
    // Wait for initial load
    await expect(page.getByText("Beacon")).toBeVisible();

    // Change the distance
    const distanceInput = page.locator('input[name="distance"]');
    await distanceInput.fill("50");

    // The table should still show quantum drives
    await expect(page.getByText("Beacon")).toBeVisible();
    await expect(page.getByText("Expedition")).toBeVisible();
  });

  test("Shows powered by attribution", async ({ page }) => {
    await expect(page.getByText("powered by")).toBeVisible();
    await expect(page.locator('a[href*="Erec"]')).toBeVisible();
  });
});
