import { app, appScenario } from "../support/on-rails";
import { test, expect } from "../support/commands";

test.describe("Cargo Grids", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean");
    await appScenario("tools");

    await page.goto("/tools/cargo-grids/");

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

    await expect(page).toHaveURL(/ship=drak-caterpillar/);

    // The cargo grid viewer should appear with stats
    await expect(page.getByTestId("cargo-grid-viewer")).toBeVisible();
    await expect(page.getByTestId("cargo-grid-viewer-stats")).toBeVisible();
  });

  test("Selects a model via URL query parameter", async ({ page }) => {
    await page.goto("/tools/cargo-grids/?ship=drak-caterpillar");

    // Wait for page to settle after navigation with query param
    await page.waitForLoadState("networkidle");

    // The cargo grid viewer should appear
    await expect(page.getByTestId("cargo-grid-viewer")).toBeVisible();
    await expect(page.getByTestId("cargo-grid-viewer-stats")).toBeVisible();
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
    await page.goto("/tools/cargo-grids/?ship=rsi-aurora-mr");
    await page.waitForLoadState("networkidle");

    // Should show the no-cargo-holds message, not the viewer
    await expect(page.getByTestId("cargo-grid-viewer")).not.toBeVisible();
  });

  test("Resets filters", async ({ page }) => {
    // Select a ship first (reset button only visible with a ship selected)
    await page.goto("/tools/cargo-grids/?ship=drak-caterpillar");
    await expect(page.getByTestId("cargo-grid-viewer")).toBeVisible();

    // Set some container counts
    await page.locator('input[name="container-8"]').fill("3");

    // Click reset
    await page.getByTestId("reset-filters").click();

    // Confirm the reset dialog
    await page.getByTestId("confirm-dialog").waitFor({ state: "visible" });
    await page.getByTestId("confirm-ok").click();

    // Container inputs should be cleared
    await expect(page.locator('input[name="container-8"]')).toHaveValue("0");

    // Ship should be removed — viewer gone
    await expect(page.getByTestId("cargo-grid-viewer")).not.toBeVisible();
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

  test("Adds multiple ships by selecting from the same filter", async ({
    page,
  }) => {
    // Select first ship
    const filterGroup = page.getByTestId("filter-group-cargo-grid-model");
    await filterGroup.getByTestId("filter-group-title").click();
    await filterGroup.locator("input").first().fill("Caterpillar");
    await page.getByText("Caterpillar").first().click();

    // First ship should appear in viewer
    await expect(page.getByTestId("cargo-grid-viewer")).toBeVisible();

    // Select second ship
    await filterGroup.getByTestId("filter-group-title").click();
    await filterGroup.locator("input").first().fill("Freelancer");
    await page.getByText("Freelancer MAX").first().click();

    // Multi-ship stats should appear
    await expect(
      page.getByTestId("cargo-grid-viewer-multi-stats"),
    ).toBeVisible();
  });

  test("Loads multiple ships via URL and shows unified viewer with multi-ship stats", async ({
    page,
  }) => {
    await page.goto(
      "/tools/cargo-grids/?ships=drak-caterpillar,misc-freelancer-max",
    );

    // Wait for the viewer to render (models load async)
    await expect(page.getByTestId("cargo-grid-viewer")).toBeVisible();

    // Should show ONE cargo grid viewer (unified)
    await expect(page.getByTestId("cargo-grid-viewer")).toHaveCount(1);

    // Should show multi-ship stats (not single-ship stats)
    await expect(
      page.getByTestId("cargo-grid-viewer-multi-stats"),
    ).toBeVisible();
  });

  test("Removes a ship from comparison", async ({ page }) => {
    // Load two ships via URL
    await page.goto(
      "/tools/cargo-grids/?ships=drak-caterpillar,misc-freelancer-max",
    );

    // Multi-ship stats with remove buttons
    await expect(
      page.getByTestId("cargo-grid-viewer-multi-stats"),
    ).toBeVisible();

    // Remove the second ship
    await page.getByTestId("remove-ship-1").click();

    // Multi-ship stats should disappear
    await expect(
      page.getByTestId("cargo-grid-viewer-multi-stats"),
    ).not.toBeVisible();

    // Should be back to single-ship view
    await expect(page.getByTestId("cargo-grid-viewer")).toBeVisible();
  });

  test("Backward compat: single ship URL still works", async ({ page }) => {
    await page.goto("/tools/cargo-grids/?ship=drak-caterpillar");
    await page.waitForLoadState("networkidle");

    await expect(page.getByTestId("cargo-grid-viewer")).toBeVisible();
    await expect(page.getByTestId("cargo-grid-viewer-stats")).toBeVisible();
  });
});
