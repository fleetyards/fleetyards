import { test, expect } from "../support/commands";
import { app, appScenario } from "../support/on-rails";

const EMBED_TIMEOUT = { timeout: 30000 };

test.describe("EmbedV2Fleet", () => {
  test.beforeEach(async () => {
    await app("clean");
    await appScenario("embed");
  });

  test("Default Workflow", async ({ page }) => {
    await page.goto("/embed-v2-fleet-test");

    await expect(page.getByTestId("model-MISC-freelancer")).toHaveCount(
      1,
      EMBED_TIMEOUT,
    );

    await expect(page.getByTestId("model-MISC-freelancer").getByTestId("top-metrics")).toBeVisible();

    await page.getByTestId("fleetview-details-button").click();

    await expect(
      page.getByTestId("model-MISC-freelancer").getByTestId("top-metrics"),
    ).not.toBeVisible();

    await page.getByTestId("fleetview-grouped-button").click();

    await expect(page.getByTestId("model-MISC-freelancer")).toHaveCount(2);

    await page.getByTestId("fleetview-fleetchart-button").click();

    await expect(page.getByTestId("model-MISC-freelancer")).toHaveCount(2);

    await page.getByTestId("fleetview-grouped-button").click();

    await expect(page.getByTestId("model-MISC-freelancer")).toHaveCount(1);
  });
});
