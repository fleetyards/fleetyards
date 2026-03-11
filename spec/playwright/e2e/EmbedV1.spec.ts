import { test, expect } from "../support/commands";
import { app } from "../support/on-rails";

test.describe("EmbedV1", () => {
  test("Default Workflow", async ({ page }) => {
    await app("clean");

    await page.goto("/embed-test");

    await expect(page.locator(".model-300i")).toHaveCount(1);

    await expect(page.locator(".model-300i .top-metrics")).toBeVisible();

    await page.getByTestId("fleetview-details-button").click();

    await expect(page.locator(".model-300i .top-metrics")).not.toBeVisible();

    await page.getByTestId("fleetview-grouped-button").click();

    await expect(page.locator(".model-300i")).toHaveCount(2);

    await page.getByTestId("fleetview-fleetchart-button").click();

    await expect(page.locator(".model-300i")).toHaveCount(2);

    await page.getByTestId("fleetview-grouped-button").click();

    await expect(page.locator(".model-300i")).toHaveCount(1);
  });
});
