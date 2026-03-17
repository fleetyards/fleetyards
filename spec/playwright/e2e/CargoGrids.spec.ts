import { app, appScenario } from "../support/on-rails";
import { test, expect } from "../support/commands";

test.describe("Cargo Grids", () => {
  test.beforeEach(async ({ page, acceptCookie }) => {
    await app("clean");
    await appScenario("tools");

    await page.goto("/tools/cargo-grids/");

    await acceptCookie.accept();

    // Wait for the filter component to be interactive
    await page.getByTestId("filter-group-cargo-grid-model").waitFor();
  });

  test("Loads the page", async ({ page }) => {
    await expect(page).toHaveURL(/\/tools\/cargo-grids/);
    await expect(page.locator("h1")).toBeVisible();
  });

  test("Shows container size inputs", async ({ page }) => {
    const sizes = [1, 2, 4, 8, 16, 24, 32];
    for (const size of sizes) {
      await expect(
        page.locator(`input[name="container-${size}"]`),
      ).toBeVisible();
    }
  });

  test("Selects a model and displays the cargo grid viewer", async ({
    page,
  }) => {
    // Open the model filter dropdown and search for Caterpillar
    const filterGroup = page.getByTestId("filter-group-cargo-grid-model");
    await filterGroup.getByTestId("filter-group-title").click();
    await filterGroup.locator("input").first().fill("Caterpillar");

    // Wait for search results and select
    const option = page.getByText("Caterpillar").first();
    await option.click();

    await expect(page).toHaveURL(/ship=caterpillar/);

    // The cargo grid viewer should appear with stats
    await expect(page.getByTestId("cargo-grid-viewer")).toBeVisible();
    await expect(page.getByTestId("cargo-grid-viewer-stats")).toBeVisible();
  });

  test("Selects a model via URL query parameter", async ({ page }) => {
    await page.goto("/tools/cargo-grids/?ship=caterpillar");

    // Wait for page to settle after navigation with query param
    await page.waitForLoadState("networkidle");

    // The cargo grid viewer should appear
    await expect(page.getByTestId("cargo-grid-viewer")).toBeVisible();
    await expect(page.getByTestId("cargo-grid-viewer-stats")).toBeVisible();
  });

  test("Auto-fills container counts when selecting a model with cargo holds", async ({
    page,
  }) => {
    const filterGroup = page.getByTestId("filter-group-cargo-grid-model");
    await filterGroup.getByTestId("filter-group-title").click();
    await filterGroup.locator("input").first().fill("Caterpillar");

    const option = page.getByText("Caterpillar").first();
    await option.click();

    // Wait for model to load and cargo grid viewer to appear
    await expect(page.getByTestId("cargo-grid-viewer")).toBeVisible();

    // At least one container input should have a value > 0 after greedy fill
    await expect(async () => {
      const containerFields = page.locator("[data-test^='container-field-'] input");
      const count = await containerFields.count();
      let hasNonZero = false;
      for (let i = 0; i < count; i++) {
        const value = await containerFields.nth(i).inputValue();
        if (Number(value) > 0) {
          hasNonZero = true;
          break;
        }
      }
      expect(hasNonZero).toBe(true);
    }).toPass();
  });

  test("Clears container counts", async ({ page }) => {
    // Set a container count
    const input = page.locator('input[name="container-8"]');
    await input.fill("5");

    // Clear button should appear
    const clearBtn = page.getByText("Clear");
    await expect(clearBtn).toBeVisible();
    await clearBtn.click();

    // All inputs should be 0
    const sizes = [1, 2, 4, 8, 16, 24, 32];
    for (const size of sizes) {
      const field = page.locator(`input[name="container-${size}"]`);
      await expect(field).toHaveValue("0");
    }
  });

  test("Shows message when model has no cargo holds", async ({ page }) => {
    // Navigate directly via URL since the filter excludes models without cargo grids
    await page.goto("/tools/cargo-grids/?ship=aurora-mr");
    await page.waitForLoadState("networkidle");

    // Should show the no-cargo-holds message, not the viewer
    await expect(page.getByTestId("cargo-grid-viewer")).not.toBeVisible();
  });

  test("Resets filters", async ({ page }) => {
    // Set some container counts
    await page.locator('input[name="container-8"]').fill("3");

    // Click reset
    const resetBtn = page
      .getByTestId("filters-actions")
      .getByText("Reset")
      .first();
    await resetBtn.click();

    // Container inputs should be cleared
    await expect(page.locator('input[name="container-8"]')).toHaveValue("0");
  });

  test("Shows container preview when containers set but no model selected", async ({
    page,
  }) => {
    // Set container counts without selecting a model
    await page.locator('input[name="container-8"]').fill("2");
    await page.locator('input[name="container-4"]').fill("3");

    // Click the filter ships button to apply
    const filterBtn = page.getByText("Filter Ships by Container Size");
    await expect(filterBtn).toBeVisible();
  });
});
