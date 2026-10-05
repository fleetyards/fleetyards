import { test, expect } from "../support/commands";
import { app, appScenario } from "../support/on-rails";

/*
 * The squadron editor is one form drawn across three tabs, so what was typed on
 * one tab has to survive a visit to another and a save the server refuses.
 */

const NEW_SQUADRON = "/fleets/squads/squadrons/new/";

test.describe("Squadrons", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean");
    await appScenario("squadrons");

    await page.goto("/login/");

    await page.locator("input[name='login']").fill("squadrons");
    await page.locator("input[name='password']").fill("password");

    const sessionCreated = page.waitForResponse(
      (response) =>
        response.url().includes("/api/v1/sessions") &&
        response.request().method() === "POST",
    );

    await page.getByTestId("submit-login").click();

    await sessionCreated;

    await expect(page).not.toHaveURL(/\/login/);

    await page.goto(NEW_SQUADRON);
    await expect(page.locator("input[name='name']")).toBeVisible();
  });

  test("keeps the details across a tab switch", async ({ page }) => {
    await page.locator("input[name='name']").fill("Bravo Wing");
    await page.locator("textarea[name='shortDescription']").fill("Escorts");

    await page.locator(`a[href$="${NEW_SQUADRON}appearance/"]`).click();
    await expect(page).toHaveURL(/\/new\/appearance\//);

    await page.locator(`a[href$="${NEW_SQUADRON}"]`).click();
    await expect(page).toHaveURL(/\/new\/$/);

    await expect(page.locator("input[name='name']")).toHaveValue("Bravo Wing");
    await expect(page.locator("textarea[name='shortDescription']")).toHaveValue(
      "Escorts",
    );
  });

  test("keeps the form when the server refuses it", async ({ page }) => {
    await page.locator("input[name='name']").fill("Alpha Wing");
    await page.locator("textarea[name='shortDescription']").fill("Escorts");

    const refused = page.waitForResponse(
      (response) =>
        response.url().includes("/api/v1/fleets/squads/squadrons") &&
        response.request().method() === "POST",
    );

    await page.getByTestId("submit-form").click();

    expect((await refused).status()).toBe(400);
    await expect(page.getByTestId("notification-alert")).toBeVisible();

    await expect(page).toHaveURL(/\/new\/$/);
    await expect(page.locator("input[name='name']")).toHaveValue("Alpha Wing");
    await expect(page.locator("textarea[name='shortDescription']")).toHaveValue(
      "Escorts",
    );

    await page.locator(`a[href$="${NEW_SQUADRON}appearance/"]`).click();
    await page.locator(`a[href$="${NEW_SQUADRON}"]`).click();

    await expect(page.locator("input[name='name']")).toHaveValue("Alpha Wing");
  });
});
