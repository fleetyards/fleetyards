import { app, appScenario } from "../support/on-rails";
import { test, expect } from "../support/commands";

const openFirstFeature = async (page: import("@playwright/test").Page) => {
  await page.goto("/admin/features/");
  await page.waitForLoadState("networkidle");
  await page
    .getByTestId("list-group-item")
    .first()
    .getByTestId("edit-feature")
    .click();
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

  test("Shows feature flags list", async ({ page }) => {
    await page.goto("/admin/features/");

    // Wait for feature list to load from API
    await page.waitForLoadState("networkidle");
    await expect(page.getByTestId("list-group-item").first()).toBeVisible();

    // Feature names should be visible
    await expect(page.getByTestId("feature-name").first()).toBeVisible();
  });

  test("Shows feature state pills", async ({ page }) => {
    await page.goto("/admin/features/");

    // Wait for feature list to load from API
    await page.waitForLoadState("networkidle");
    await expect(page.getByTestId("list-group-item").first()).toBeVisible();

    // State pills (on/off/conditional) should be present
    const pills = page.getByTestId("pill");
    await expect(pills.first()).toBeVisible();
  });

  test("Toggles a feature on", async ({ page, notification }) => {
    await page.goto("/admin/features/");

    // Wait for feature list to load from API
    await page.waitForLoadState("networkidle");
    await expect(page.getByTestId("list-group-item").first()).toBeVisible();

    // Find a toggle button and click it
    const toggleBtn = page
      .getByTestId("list-group-item")
      .first()
      .getByTestId("toggle-feature");
    await toggleBtn.click();

    // Should show success notification
    await notification.success("updated");
  });

  test("Opens a feature's own page from the list", async ({ page }) => {
    await page.goto("/admin/features/");

    await page.waitForLoadState("networkidle");
    await expect(page.getByTestId("list-group-item").first()).toBeVisible();

    await page
      .getByTestId("list-group-item")
      .first()
      .getByTestId("edit-feature")
      .click();

    await expect(page).toHaveURL(/\/admin\/features\/[^/]+\/$/);
    await expect(page.getByTestId("feature-heading")).toBeVisible();
    await expect(page.getByTestId("feature-global")).toBeVisible();
  });

  test("Toggles user self-service on the users tab", async ({
    page,
    notification,
  }) => {
    await openFirstFeature(page);
    await page.goto(`${page.url()}users/`);

    await page.getByTestId("toggle-self-service").click();

    await notification.success("updated");
  });

  test("Toggles fleet self-service on the fleets tab", async ({
    page,
    notification,
  }) => {
    await openFirstFeature(page);
    await page.goto(`${page.url()}fleets/`);

    await page.getByTestId("toggle-fleet-self-service").click();

    await notification.success("updated");
  });

  test("Adds a group to a feature", async ({ page, notification }) => {
    await openFirstFeature(page);

    await page.getByTestId("add-group-testers").click();

    await notification.success("added");
  });

  test("Adds a fleet through the picker on the fleets tab", async ({
    page,
    notification,
  }) => {
    await openFirstFeature(page);
    await page.goto(`${page.url()}fleets/`);

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
