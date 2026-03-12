import { test, expect } from "../support/commands";
import { app, appFactories, appScenario } from "../support/on-rails";

test.describe("Hangar", () => {
  test.beforeEach(async ({ page, acceptCookie }) => {
    await app("clean");
    await appScenario("hangar");

    await page.goto("/");

    await acceptCookie.accept();
  });

  test("Shows Preview", async ({ page, nav }) => {
    await nav.click("hangar-preview");

    await expect(page).toHaveURL(/\/hangar\/preview\//);

    await page.getByTestId("login").click();

    await expect(page).toHaveURL(/\/login/);

    await nav.click("hangar");

    await expect(page).toHaveURL(/\/login/);

    await page.goto("/");

    await nav.click("hangar");

    await expect(page).toHaveURL(/\/login/);
  });

  test("Default Workflow", async ({ page, nav }) => {
    await nav.click("login");

    await expect(page).toHaveURL(/\/login/);

    await appFactories([
      ["create", "user", { username: "test", password: "password" }],
    ]);

    await page.locator("input[name='login']").fill("test");
    await page.locator("input[name='password']").fill("password");
    await page.getByTestId("submit-login").click();

    await expect(page).toHaveURL(/\//);

    await nav.click("models");

    await expect(page).toHaveURL(/\/ships\//);

    await page
      .locator(".model-panel-300i")
      .getByTestId("add-to-hangar")
      .click();

    await nav.click("hangar");

    await expect(
      page.locator(".model-panel-300i .panel-title a").first(),
    ).toContainText("300i");

    await page
      .locator(".model-panel-300i")
      .getByTestId("300i-dropdown")
      .click();
    await page
      .locator(".panel-btn-dropdown__list.visible")
      .locator("[data-test='edit-name']")
      .click();

    await page.getByTestId("input-vehicle-name").clear();
    await page.getByTestId("input-vehicle-name").fill("Enterprise");

    await page.getByTestId("vehicle-save").click();

    await expect(
      page.locator(".model-panel-300i .panel-title a").first(),
    ).toContainText("Enterprise");

    await page.getByTestId("fleetchart-link").click();
  });
});
