import { test, expect } from "../support/commands";
import { app, appScenario } from "../support/on-rails";

test.describe("Images", () => {
  test.beforeEach(async ({ page, acceptCookie }) => {
    await app("clean");
    await appScenario("images");

    await page.goto("/");

    await acceptCookie.accept();
  });

  test("Loads", async ({ page, nav }) => {
    await nav.click("images");

    await expect(page).toHaveURL(/\/images/);

    const images = page.locator(".images a");
    await expect(images).toHaveCount(20);
  });
});
