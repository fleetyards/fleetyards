import type { Page } from "@playwright/test";
import { app, appScenario } from "../support/on-rails";
import { test, expect } from "../support/commands";

const driveRow = (page: Page, name: string) =>
  page.getByRole("row").filter({ hasText: name });

const header = (page: Page, label: string) =>
  page.getByRole("row").first().getByRole("link", { name: label });

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

    const head = page.getByRole("row").first();
    await expect(head).toContainText("Quantum Drive");
    await expect(head).toContainText("Size");
    await expect(head).toContainText("Grade");
    await expect(head).toContainText("Fuel Usage");
    await expect(head).toContainText("Travel Time");
  });

  test("Calculates travel time and fuel usage for the default distance", async ({
    page,
  }) => {
    await expect(driveRow(page, "Beacon")).toContainText("01:18");
    await expect(driveRow(page, "Beacon")).toContainText("0.1 SCU");

    await expect(driveRow(page, "Expedition")).toContainText("01:55");
    await expect(driveRow(page, "Expedition")).toContainText("0.44 SCU");
  });

  test("Shows each drive's size and grade", async ({ page }) => {
    await expect(driveRow(page, "Beacon")).toContainText("S1");
    await expect(driveRow(page, "Beacon")).toContainText("A");

    await expect(driveRow(page, "Expedition")).toContainText("S2");
    await expect(driveRow(page, "Expedition")).toContainText("C");
  });

  test("Ranks the fastest drive first", async ({ page }) => {
    await expect(page.getByText("Beacon")).toBeVisible();

    await expect(page.locator("tbody tr").first()).toContainText("Beacon");
    await expect(page.locator("tbody tr").first()).toContainText("01");
    await expect(page.locator("tbody tr").nth(1)).toContainText("Expedition");
  });

  test("Updates travel times when distance changes", async ({ page }) => {
    await expect(driveRow(page, "Beacon")).toContainText("01:18");

    await page.locator('input[name="distance"]').fill("50");

    await expect(driveRow(page, "Beacon")).toContainText("03:04");
    await expect(driveRow(page, "Expedition")).toContainText("04:39");
  });

  test("Jumps to a preset distance", async ({ page }) => {
    await expect(driveRow(page, "Beacon")).toContainText("01:18");

    await page.getByRole("button", { name: "Across Stanton" }).click();

    await expect(page.locator('input[name="distance"]')).toHaveValue("40");
    await expect(page).toHaveURL(/[?&]distance=40/);
    await expect(driveRow(page, "Beacon")).not.toContainText("01:18");
  });

  // The order is applied here rather than by the endpoint, which pins its own,
  // but it still travels in `?s=` so a link carries it.
  test("Carries the sort order in the URL", async ({ page }) => {
    await expect(page.locator("tbody tr").first()).toContainText("Beacon");

    await header(page, "Quantum Drive").click();
    await expect(page).toHaveURL(/[?&]s=name(\+|%20)asc/);
    await expect(page.locator("tbody tr").first()).toContainText("Beacon");

    await header(page, "Quantum Drive").click();
    await expect(page).toHaveURL(/[?&]s=name(\+|%20)desc/);
    await expect(page.locator("tbody tr").first()).toContainText("Expedition");
  });

  test("Carries the filters in the URL", async ({ page }) => {
    await expect(page.getByText("Expedition")).toBeVisible();

    await page.getByRole("button", { name: "S2", exact: true }).click();

    await expect(page).toHaveURL(/[?&]size=2/);
    await expect(page.getByText("Expedition")).toBeVisible();
    await expect(page.getByText("Beacon")).toBeHidden();

    await page.getByRole("button", { name: "Reset" }).click();
    await expect(page).not.toHaveURL(/[?&]size=/);
    await expect(page.getByText("Beacon")).toBeVisible();
  });

  // The point of keeping the state in the query: the link is the view.
  test("Restores distance, filter and order from a shared link", async ({
    page,
  }) => {
    await page.goto("/tools/travel-times/?distance=50&size=2&s=name+desc");

    await expect(page.locator('input[name="distance"]')).toHaveValue("50");
    await expect(page.getByText("Expedition")).toBeVisible();
    await expect(page.getByText("Beacon")).toBeHidden();
    await expect(driveRow(page, "Expedition")).toContainText("04:39");
  });

  test("Shows powered by attribution", async ({ page }) => {
    await expect(page.getByText("powered by")).toBeVisible();
    await expect(page.locator('a[href*="Erec"]')).toBeVisible();
  });
});
