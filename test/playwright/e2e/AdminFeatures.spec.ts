import { app, appScenario } from "../support/on-rails";
import { test, expect } from "../support/commands";

const openFirstFeature = async (page: import("@playwright/test").Page) => {
  await page.goto("/admin/features/");
  await page.waitForLoadState("networkidle");
  await page.getByTestId("feature-row").first().click();
  await expect(page.getByTestId("feature-heading")).toBeVisible();
};

test.describe("Admin Features", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean");
    await appScenario("admin_features");

    // Login to admin
    await page.goto("/admin/login/");
    await page.locator("input[name='login']").fill("admin_features");
    await page.locator("input[name='password']").fill("password123");
    await page.getByTestId("submit-login").click();

    // Wait for dashboard to load
    await expect(page).toHaveURL(/\/admin\/?$/);
  });

  test("Loads the features page", async ({ page }) => {
    await page.goto("/admin/features/");

    await expect(page).toHaveURL(/\/admin\/features/);
    await expect(page.locator("h1")).toBeVisible();
  });

  test("Shows each flag with its state and who has it", async ({ page }) => {
    await page.goto("/admin/features/");

    await page.waitForLoadState("networkidle");
    const row = page.getByTestId("feature-row").first();

    await expect(row.getByTestId("feature-name")).toBeVisible();
    await expect(row.getByTestId("pill")).toBeVisible();
    await expect(row.getByTestId("feature-on-for")).toBeVisible();
  });

  test("Filters the list by name", async ({ page }) => {
    await page.goto("/admin/features/");
    await page.waitForLoadState("networkidle");

    await page.locator("input[name='features-filter']").fill("holo_ar");

    await expect(page.getByTestId("feature-row")).toHaveCount(1);
    await expect(page.getByTestId("feature-name")).toHaveText("holo_ar");
  });

  test("Opens a feature's own page from the list", async ({ page }) => {
    await openFirstFeature(page);

    await expect(page).toHaveURL(/\/admin\/features\/[^/]+\/$/);
    await expect(page.getByTestId("feature-on-for")).toBeVisible();
    await expect(page.getByTestId("feature-history")).toBeVisible();
  });

  test("Opens a feature to everyone", async ({ page, notification }) => {
    await openFirstFeature(page);

    await page.getByTestId("feature-enable").click();

    await notification.success("updated");
    await expect(page.getByTestId("feature-enable")).toBeHidden();
  });

  test("Toggles user self-service", async ({ page, notification }) => {
    await openFirstFeature(page);

    await page
      .getByTestId("toggle-self-service")
      .locator("button.base-toggle")
      .click();

    await notification.success("updated");
  });

  test("Toggles fleet self-service", async ({ page, notification }) => {
    await openFirstFeature(page);

    await page
      .getByTestId("toggle-fleet-self-service")
      .locator("button.base-toggle")
      .click();

    await notification.success("updated");
  });

  test("Adds a group to a feature", async ({ page, notification }) => {
    await openFirstFeature(page);

    await page.getByTestId("feature-group-testers").getByRole("button").click();

    await notification.success("added");
  });

  test("Applies a share of users only on Apply", async ({
    page,
    notification,
  }) => {
    await openFirstFeature(page);

    await page.locator("input[name='feature-actors']").fill("10");
    await page.getByTestId("percentage-apply-actors").click();

    await notification.success("updated");
  });

  test("Adds a fleet through the picker", async ({ page, notification }) => {
    await openFirstFeature(page);
    await page.getByTestId("feature-actors-tab-fleets").click();

    const picker = page.getByTestId("base-select-feature-fleet");
    await picker.getByTestId("base-select-title").click();
    await picker.locator("input").fill("E2EFEATUREFLEET");
    await picker
      .getByRole("option", { name: /E2E Feature Fleet \(E2EFEATUREFLEET\)/ })
      .click();
    await page.getByTestId("feature-add-fleet").click();

    await notification.success("added");
    await expect(page.getByTestId("feature-actors-fleets")).toContainText(
      "E2EFEATUREFLEET",
    );
  });
});
