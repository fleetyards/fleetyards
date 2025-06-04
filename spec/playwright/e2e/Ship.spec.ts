import { app, appScenario } from "../support/on-rails";
import { test, expect } from "../support/commands";

test.describe("Ship", () => {
  test.beforeEach(async ({ page, acceptCookie }) => {
    await app("clean");
    await appScenario("ships");

    await page.goto("/");

    await acceptCookie.accept();
  });

  test("Loads", async ({ page, nav, dropdown }) => {
    await nav.click("ships");

    await expect(
      page.locator(".panel-heading__title a span").getByText("Ironclad"),
    ).toBeVisible();

    await page
      .locator(".model-panel-ironclad .panel-heading__title a")
      .first()
      .click();

    await expect(page).toHaveURL(/\/ships\/ironclad/);

    await expect(page.locator("h1")).toContainText("Ironclad");

    await dropdown.click("model", "compare");

    await expect(page).toHaveURL(/\/compare\/\?models%5B%5D=ironclad/);
  });
});
