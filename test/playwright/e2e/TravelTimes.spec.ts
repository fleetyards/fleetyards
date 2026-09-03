import type { Page } from "@playwright/test";
import { app, appScenario } from "../support/on-rails";
import { test, expect } from "../support/commands";

const driveRow = (page: Page, name: string) =>
  page.getByRole("row").filter({ hasText: name });

test.describe("Travel Times", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean");
    await appScenario("tools");

    await page.goto("/tools/travel-times/");
  });

  test("Loads the page", async ({ page }) => {
    await expect(page).toHaveURL(/\/tools\/travel-times/);
    await expect(page.locator("h1")).toBeVisible();
  });

  test("Shows distance input with default value", async ({ page }) => {
    const distanceInput = page.locator('input[name="distance"]');
    await expect(distanceInput).toBeVisible();
    await expect(distanceInput).toHaveValue("20");
  });

  test("Shows quantum drives list", async ({ page }) => {
    await expect(page.getByText("Beacon")).toBeVisible();
    await expect(page.getByText("Expedition")).toBeVisible();
  });

  test("Labels every column", async ({ page }) => {
    await expect(page.getByText("Beacon")).toBeVisible();

    const header = page.getByRole("row").first();
    await expect(header).toContainText("Quantum Drive");
    await expect(header).toContainText("Fuel Usage");
    await expect(header).toContainText("Travel Time");
  });

  test("Calculates travel time and fuel usage for the default distance", async ({
    page,
  }) => {
    await expect(driveRow(page, "Beacon")).toContainText("01:18");
    await expect(driveRow(page, "Beacon")).toContainText("0.1 SCU");

    await expect(driveRow(page, "Expedition")).toContainText("01:55");
    await expect(driveRow(page, "Expedition")).toContainText("0.44 SCU");
  });

  test("Sorts the fastest drive first", async ({ page }) => {
    await expect(page.getByText("Beacon")).toBeVisible();

    await expect(page.locator("tbody tr").first()).toContainText("Beacon");
    await expect(page.locator("tbody tr").nth(1)).toContainText("Expedition");
  });

  test("Updates travel times when distance changes", async ({ page }) => {
    await expect(driveRow(page, "Beacon")).toContainText("01:18");

    const distanceInput = page.locator('input[name="distance"]');
    await distanceInput.fill("50");

    await expect(driveRow(page, "Beacon")).toContainText("03:04");
    await expect(driveRow(page, "Expedition")).toContainText("04:39");
  });

  test("Shows powered by attribution", async ({ page }) => {
    await expect(page.getByText("powered by")).toBeVisible();
    await expect(page.locator('a[href*="Erec"]')).toBeVisible();
  });
});
