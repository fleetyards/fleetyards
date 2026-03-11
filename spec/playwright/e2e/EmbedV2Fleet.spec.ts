import { test, expect } from "../support/commands";
import { app } from "../support/on-rails";

test.describe("EmbedV2Fleet", () => {
  test("Default Workflow", async ({ page }) => {
    await app("clean");

    await page.goto("/embed-v2-fleet-test");

    await expect(page.locator(".model-freelancer")).toHaveCount(1);

    await expect(page.locator(".model-freelancer .top-metrics")).toBeVisible();

    await page.getByTestId("fleetview-details-button").click();

    await expect(
      page.locator(".model-freelancer .top-metrics"),
    ).not.toBeVisible();

    await page.getByTestId("fleetview-grouped-button").click();

    await expect(page.locator(".model-freelancer")).toHaveCount(2);

    await page.getByTestId("fleetview-fleetchart-button").click();

    await expect(page.locator(".model-freelancer")).toHaveCount(2);

    await page.getByTestId("fleetview-grouped-button").click();

    await expect(page.locator(".model-freelancer")).toHaveCount(1);
  });
});
