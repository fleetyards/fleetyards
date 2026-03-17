import { app, appScenario } from "../support/on-rails";
import { test, expect } from "../support/commands";

test.describe("Ships", () => {
  test.beforeEach(async ({ page, acceptCookie }) => {
    await app("clean");
    await appScenario("ships");

    await page.goto("/");

    await acceptCookie.accept();
  });

  test("Loads", async ({ page, nav }) => {
    await nav.click("ships");

    await expect(page).toHaveURL(/\/ships/);

    const ships = page.locator("[data-test^='model-panel-']");
    await expect(ships).toHaveCount(2);

    await expect(
      page.getByTestId("panel-heading-title").locator("span").getByText("Corsair"),
    ).toBeVisible();
  });
});
