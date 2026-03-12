import { app, appScenario } from "../support/on-rails";
import { test, expect } from "../support/commands";

test.describe("Admin Cargo Holds", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean");
    await appScenario("admin_cargo_holds");

    // Login to admin
    await page.goto("/admin/login/");
    await page.locator("input[name='login']").fill("admin_cargo");
    await page.locator("input[name='password']").fill("password123");
    await page.getByTestId("submit-login").click();

    // Wait for dashboard to load
    await expect(page).toHaveURL(/\/admin\/?$/);
  });

  test("Navigates to model list", async ({ page }) => {
    await page.goto("/admin/models/");

    await expect(page).toHaveURL(/\/admin\/models/);

    // Should show the Caterpillar model in the list
    await expect(page.getByText("Caterpillar")).toBeVisible();
  });

  test("Opens model edit page", async ({ page }) => {
    await page.goto("/admin/models/");

    // Click on the Caterpillar model to edit
    await page.getByText("Caterpillar").first().click();

    await expect(page).toHaveURL(/\/admin\/models\/.+\/edit/);
  });

  test("Shows cargo holds tab on model edit", async ({ page }) => {
    await page.goto("/admin/models/");

    // Click on the Caterpillar model
    await page.getByText("Caterpillar").first().click();

    await expect(page).toHaveURL(/\/admin\/models\/.+\/edit/);

    // Navigate to cargo holds tab
    const cargoHoldsTab = page.getByText("Cargo Holds").first();
    await cargoHoldsTab.click();

    await expect(page).toHaveURL(/\/cargo-holds/);
  });

  test("Shows cargo holds list", async ({ page }) => {
    await page.goto("/admin/models/");

    // Click on the Caterpillar model
    await page.getByText("Caterpillar").first().click();

    // Navigate to cargo holds tab
    const cargoHoldsTab = page.getByText("Cargo Holds").first();
    await cargoHoldsTab.click();

    // Should show the cargo holds
    await expect(page.getByText("Cargo Front")).toBeVisible();
    await expect(page.getByText("Cargo Rear")).toBeVisible();

    // Should show dimensions
    await expect(page.getByText("8 SCU")).toBeVisible();
    await expect(page.getByText("16 SCU")).toBeVisible();
  });

  test("Shows auto offset by default", async ({ page }) => {
    await page.goto("/admin/models/");

    await page.getByText("Caterpillar").first().click();

    const cargoHoldsTab = page.getByText("Cargo Holds").first();
    await cargoHoldsTab.click();

    // Both holds should show Auto offset
    const autoLabels = page.getByText("Auto");
    await expect(autoLabels.first()).toBeVisible();
  });

  test("Opens edit mode for a cargo hold", async ({ page }) => {
    await page.goto("/admin/models/");

    await page.getByText("Caterpillar").first().click();

    const cargoHoldsTab = page.getByText("Cargo Holds").first();
    await cargoHoldsTab.click();

    // Wait for cargo holds list to load
    await page.waitForSelector(".list-group__item");

    // Click edit button on first cargo hold
    const editBtn = page
      .locator(".list-group__item")
      .first()
      .locator("i.fad.fa-pencil")
      .first();
    await editBtn.click();

    // Should show offset and rotation inputs
    await expect(page.locator('input[name="offsetX"]')).toBeVisible();
    await expect(page.locator('input[name="offsetY"]')).toBeVisible();
    await expect(page.locator('input[name="offsetZ"]')).toBeVisible();
    await expect(page.locator('input[name="rotation"]')).toBeVisible();
  });

  test("Saves cargo hold offset", async ({ page }) => {
    await page.goto("/admin/models/");

    await page.getByText("Caterpillar").first().click();

    const cargoHoldsTab = page.getByText("Cargo Holds").first();
    await cargoHoldsTab.click();

    // Wait for cargo holds list to load
    await page.waitForSelector(".list-group__item");

    // Click edit button on first cargo hold
    const editBtn = page
      .locator(".list-group__item")
      .first()
      .locator("i.fad.fa-pencil")
      .first();
    await editBtn.click();

    // Fill in offset values
    await page.locator('input[name="offsetX"]').fill("1.5");
    await page.locator('input[name="offsetY"]').fill("2.0");
    await page.locator('input[name="offsetZ"]').fill("0.5");
    await page.locator('input[name="rotation"]').fill("90");

    // Click save (check icon)
    const saveBtn = page
      .locator(".list-group__item")
      .first()
      .locator("i.fad.fa-check")
      .first();
    await saveBtn.click();

    // Should exit edit mode and show the offset values
    await expect(page.locator('input[name="offsetX"]')).not.toBeVisible();
    await expect(page.getByText("1.5, 2, 0.5")).toBeVisible();
  });
});
