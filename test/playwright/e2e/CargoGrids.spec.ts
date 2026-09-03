import { app, appScenario } from "../support/on-rails";
import { test, expect } from "../support/commands";
import type { Page } from "@playwright/test";

test.describe("Cargo Grids", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean");
    await appScenario("tools");

    await page.goto("/tools/cargo-grids/");

    // Wait for the picker's trigger to be interactive
    await page.getByTestId("cargo-grid-add-ships").waitFor();
  });

  const pickShips = async (page: Page, ...slugs: string[]) => {
    await page.getByTestId("cargo-grid-add-ships").click();
    await page.getByTestId("modal").waitFor({ state: "visible" });

    for (const slug of slugs) {
      await page.getByTestId(`model-picker-card-${slug}`).click();
    }

    await page.getByTestId("model-picker-submit").click();
    await page.getByTestId("modal").waitFor({ state: "hidden" });
  };

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
    await pickShips(page, "drak-caterpillar");

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

    // Every counter empties out
    const sizes = [1, 2, 4, 8, 16, 24, 32];
    for (const size of sizes) {
      const field = page.locator(`input[name="container-${size}"]`);
      await expect(field).toHaveValue("");
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
    await expect(page.locator('input[name="container-8"]')).toHaveValue("");

    // Ship should be removed — viewer gone
    await expect(page.getByTestId("cargo-grid-viewer")).not.toBeVisible();
  });

  test("Shows container preview when containers set but no model selected", async ({
    page,
  }) => {
    // Set container counts without selecting a model
    await page.locator('input[name="container-8"]').fill("2");
    await page.locator('input[name="container-4"]').fill("3");

    // The viewer draws the load on its own, with no ship to pack it into
    await expect(page.getByTestId("cargo-grid-viewer")).toBeVisible();
  });

  test("Adds several ships in one visit to the picker", async ({ page }) => {
    await pickShips(page, "drak-caterpillar", "misc-freelancer-max");

    await expect(
      page.getByTestId("cargo-grid-viewer-multi-stats"),
    ).toBeVisible();
  });

  test("Adds a second ship in a later visit to the picker", async ({
    page,
  }) => {
    await pickShips(page, "drak-caterpillar");

    await expect(page.getByTestId("cargo-grid-viewer")).toBeVisible();

    await pickShips(page, "misc-freelancer-max");

    await expect(
      page.getByTestId("cargo-grid-viewer-multi-stats"),
    ).toBeVisible();
  });

  test("Marks a ship already on the grid as unpickable", async ({ page }) => {
    await pickShips(page, "drak-caterpillar");

    await page.getByTestId("cargo-grid-add-ships").click();
    await page.getByTestId("modal").waitFor({ state: "visible" });

    await expect(
      page.getByTestId("model-picker-card-drak-caterpillar"),
    ).toHaveClass(/model-card--disabled/);
  });

  test("Offers only ships the typed load fits into", async ({ page }) => {
    // 3x 32 SCU is more than the Caterpillar's holds take, and more than the
    // Freelancer MAX has room for at all.
    await page.locator('input[name="container-32"]').fill("3");

    await page.getByTestId("cargo-grid-add-ships").click();
    await page.getByTestId("modal").waitFor({ state: "visible" });

    // The filter arrives filled in, and it is the picker's own count that shows
    // what is being asked for.
    await expect(
      page.locator('input[name="model-picker-container-32"]'),
    ).toHaveValue("3");

    await expect(
      page.getByTestId("model-picker-card-drak-caterpillar"),
    ).toHaveCount(0);

    // Widening the filter in the modal brings them back without touching the
    // load the page is holding.
    await page.locator('input[name="model-picker-container-32"]').fill("");

    await expect(
      page.getByTestId("model-picker-card-drak-caterpillar"),
    ).toBeVisible();

    await page.locator(".modal-header a.close").click();
    await page.getByTestId("modal").waitFor({ state: "hidden" });

    await expect(page.locator('input[name="container-32"]')).toHaveValue("3");
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
