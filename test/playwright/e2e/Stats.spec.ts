import { test, expect } from "../support/commands";
import { app, appScenario } from "../support/on-rails";

test.describe("Stats", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean");
    await appScenario("ships");

    await page.goto("/");
  });

  test("Loads", async ({ page, nav }) => {
    await nav.click("stats");

    await expect(page).toHaveURL(/\/stats/);

    await expect(page.getByTestId("stats")).toBeVisible();
  });
});
