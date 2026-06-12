import { app, appScenario } from "../support/on-rails";
import { test, expect } from "../support/commands";

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
    await page.goto("/admin/maintenance/features/");

    await expect(page).toHaveURL(/\/maintenance\/features/);
    await expect(page.locator("h1")).toBeVisible();
  });

  test("Shows feature flags list", async ({ page }) => {
    await page.goto("/admin/maintenance/features/");

    // Wait for feature list to load from API
    await page.waitForLoadState("networkidle");
    await expect(page.getByTestId("list-group-item").first()).toBeVisible();

    // Feature names should be visible
    await expect(page.getByTestId("feature-name").first()).toBeVisible();
  });

  test("Shows feature state pills", async ({ page }) => {
    await page.goto("/admin/maintenance/features/");

    // Wait for feature list to load from API
    await page.waitForLoadState("networkidle");
    await expect(page.getByTestId("list-group-item").first()).toBeVisible();

    // State pills (on/off/conditional) should be present
    const pills = page.getByTestId("pill");
    await expect(pills.first()).toBeVisible();
  });

  test("Toggles a feature on", async ({ page, notification }) => {
    await page.goto("/admin/maintenance/features/");

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

  test("Opens edit mode for a feature", async ({ page }) => {
    await page.goto("/admin/maintenance/features/");

    // Wait for feature list to load from API
    await page.waitForLoadState("networkidle");
    await expect(page.getByTestId("list-group-item").first()).toBeVisible();

    // Click edit button
    const editBtn = page
      .getByTestId("list-group-item")
      .first()
      .getByTestId("start-edit");
    await editBtn.click();

    // Edit form should appear with self-service toggle and group buttons
    await expect(page.getByTestId("edit-feature")).toBeVisible();
  });

  test("Toggles self-service flag", async ({ page, notification }) => {
    await page.goto("/admin/maintenance/features/");

    // Wait for feature list to load from API
    await page.waitForLoadState("networkidle");
    await expect(page.getByTestId("list-group-item").first()).toBeVisible();

    // Open edit mode
    const editBtn = page
      .getByTestId("list-group-item")
      .first()
      .getByTestId("start-edit");
    await editBtn.click();

    // Click self-service toggle
    await page.getByTestId("toggle-self-service").click();

    await notification.success("updated");
  });

  test("Adds a group to a feature", async ({ page, notification }) => {
    await page.goto("/admin/maintenance/features/");

    // Wait for feature list to load from API
    await page.waitForLoadState("networkidle");
    await expect(page.getByTestId("list-group-item").first()).toBeVisible();

    // Open edit mode
    const editBtn = page
      .getByTestId("list-group-item")
      .first()
      .getByTestId("start-edit");
    await editBtn.click();

    // Click the "testers" group add button
    await page.getByTestId("add-group-testers").click();

    await notification.success("added");
  });
});
