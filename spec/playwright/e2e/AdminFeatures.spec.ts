import { app, appScenario } from "../support/on-rails";
import { test, expect } from "../support/commands";

test.describe("Admin Features", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean");
    await appScenario("admin_features");

    // Login to admin
    await page.goto("/admin/login/");
    await page.locator("input[name='login']").fill("admin");
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
    await page.waitForSelector(".inline-editable-list__item");

    // Feature names should be visible
    await expect(page.locator(".feature-name").first()).toBeVisible();
  });

  test("Shows feature state pills", async ({ page }) => {
    await page.goto("/admin/maintenance/features/");

    // Wait for feature list to load from API
    await page.waitForSelector(".inline-editable-list__item");

    // State pills (on/off/conditional) should be present
    const pills = page.locator(".inline-editable-list__display .pill");
    await expect(pills.first()).toBeVisible();
  });

  test("Toggles a feature on", async ({ page, notification }) => {
    await page.goto("/admin/maintenance/features/");

    // Wait for feature list to load from API
    await page.waitForSelector(".inline-editable-list__item");

    // Find a toggle button and click it
    const toggleBtn = page
      .locator(".inline-editable-list__item")
      .first()
      .locator(".inline-editable-list__actions .btn")
      .first();
    await toggleBtn.click();

    // Should show success notification
    await notification.success("updated");
  });

  test("Opens edit mode for a feature", async ({ page }) => {
    await page.goto("/admin/maintenance/features/");

    // Wait for feature list to load from API
    await page.waitForSelector(".inline-editable-list__item");

    // Click edit button (pencil icon)
    const editBtn = page
      .locator(".inline-editable-list__item")
      .first()
      .locator("i.fad.fa-pencil")
      .first();
    await editBtn.click();

    // Edit form should appear with self-service toggle and group buttons
    await expect(page.locator(".edit-feature")).toBeVisible();
    await expect(page.locator(".edit-section")).toHaveCount(3);
  });

  test("Toggles self-service flag", async ({ page, notification }) => {
    await page.goto("/admin/maintenance/features/");

    // Wait for feature list to load from API
    await page.waitForSelector(".inline-editable-list__item");

    // Open edit mode
    const editBtn = page
      .locator(".inline-editable-list__item")
      .first()
      .locator("i.fad.fa-pencil")
      .first();
    await editBtn.click();

    // Click self-service toggle
    const selfServiceBtn = page
      .locator(".edit-section")
      .first()
      .locator(".btn")
      .first();
    await selfServiceBtn.click();

    await notification.success("updated");
  });

  test("Adds a group to a feature", async ({ page, notification }) => {
    await page.goto("/admin/maintenance/features/");

    // Wait for feature list to load from API
    await page.waitForSelector(".inline-editable-list__item");

    // Open edit mode
    const editBtn = page
      .locator(".inline-editable-list__item")
      .first()
      .locator("i.fad.fa-pencil")
      .first();
    await editBtn.click();

    // Click the "testers" group add button
    const addGroupBtn = page.locator(".edit-groups .btn").filter({
      hasText: "testers",
    });
    await addGroupBtn.click();

    await notification.success("added");
  });
});
