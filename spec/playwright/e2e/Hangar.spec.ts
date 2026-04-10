import { test, expect } from "../support/commands";
import { app, appFactories, appScenario } from "../support/on-rails";

test.describe("Hangar", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean");
    await appScenario("hangar");

    await page.goto("/");
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

    await nav.click("ships");

    await expect(page).toHaveURL(/\/ships\//);

    await page
      .getByTestId("model-panel-300i")
      .getByTestId("add-to-hangar")
      .click();

    await page.getByTestId("add-to-hangar-as-normal").click();

    await nav.click("hangar");

    await expect(
      page.getByTestId("model-panel-300i").getByTestId("panel-heading-title").locator("a").first(),
    ).toContainText("300i");

    await page
      .getByTestId("model-panel-300i")
      .getByTestId("vehicle-menu")
      .click();
    await page
      .getByTestId("dropdown-list")
      .locator("[data-test='vehicle-edit-name']")
      .click();

    await page.getByTestId("modal").waitFor({ state: "visible" });

    await page.getByTestId("input-name").fill("Enterprise");

    const updateResponse = page.waitForResponse(
      (resp) => resp.url().includes("/vehicles/") && resp.request().method() === "PUT",
    );
    await page.getByTestId("vehicle-save").click();
    await updateResponse;

    await page.getByTestId("modal").waitFor({ state: "hidden" });

    await expect(
      page.getByTestId("model-panel-300i").getByTestId("panel-heading-title").locator("a").first(),
    ).toContainText("Enterprise");

    await page.getByTestId("fleetchart-link").click();
  });
});
