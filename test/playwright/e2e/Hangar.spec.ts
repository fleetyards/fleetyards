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

    const sessionCreated = page.waitForResponse(
      (response) =>
        response.url().includes("/api/v1/sessions") &&
        response.request().method() === "POST",
    );

    await page.getByTestId("submit-login").click();

    await sessionCreated;

    /*
     * Not `toHaveURL(/\//)`, which is what this waited on before: every URL
     * contains a slash, so that assertion passed instantly while the page was
     * still on /login/ and never waited for the login at all. The nav click
     * below then raced the post-login redirect, and the run failed on the next
     * assertion with the URL either still /login/ or back at /.
     */
    await expect(page).not.toHaveURL(/\/login/);

    await nav.click("ships");

    await expect(page).toHaveURL(/\/ships\//);

    await page
      .getByTestId("model-panel-orig-300i")
      .getByTestId("add-to-hangar")
      .click();

    // Same guard the name-change below already uses: without it the hangar page
    // can request its list before the vehicle exists, and the assertion that
    // follows looks for a card the server has not been told about yet.
    const vehicleCreated = page.waitForResponse(
      (response) =>
        response.url().includes("/api/v1/vehicles") &&
        response.request().method() === "POST",
    );

    await page.getByTestId("add-to-hangar-as-normal").click();

    await vehicleCreated;

    await nav.click("hangar");

    await expect(
      page.getByTestId("model-panel-orig-300i").getByTestId("panel-heading-title").locator("a").first(),
    ).toContainText("300i");

    await page
      .getByTestId("model-panel-orig-300i")
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
      page.getByTestId("model-panel-orig-300i").getByTestId("panel-heading-title").locator("a").first(),
    ).toContainText("Enterprise");

    await page.getByTestId("fleetchart-link").click();
  });
});
