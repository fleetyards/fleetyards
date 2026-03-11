import { test, expect } from "../support/commands";

test.describe("EmbedV2", () => {
  test("Default Workflow", async ({ page }) => {
    await page.goto("/embed-v2-test");

    await expect(page.locator(".model-600i-explorer")).toHaveCount(1);

    await expect(
      page.locator(".model-600i-explorer .top-metrics"),
    ).toBeVisible();

    await page.getByTestId("fleetview-details-button").click();

    await expect(
      page.locator(".model-600i-explorer .top-metrics"),
    ).not.toBeVisible();

    await page.getByTestId("fleetview-grouped-button").click();

    await expect(page.locator(".model-600i-explorer")).toHaveCount(2);

    await page.getByTestId("fleetview-fleetchart-button").click();

    await expect(page.locator(".model-600i-explorer")).toHaveCount(2);

    await page.getByTestId("fleetview-grouped-button").click();

    await expect(page.locator(".model-600i-explorer")).toHaveCount(1);
  });
});
