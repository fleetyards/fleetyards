import { test, expect } from "../support/commands";

/*
 * The two states a chart cannot draw itself out of. Both used to render an empty
 * box: the failure case drew nothing at all, and the no-data case was left to
 * Highcharts, which put up a bare pair of axes that reads as a chart that broke.
 *
 * Asserted against visual-tests/charts/, which drives every state from a
 * hand-built asyncStatus and needs no query behind it.
 */

test.describe("Charts", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/visual-tests/charts/");
    await expect(page.locator(".visual-tests")).toBeVisible();
  });

  test("a settled chart with nothing to plot says so", async ({ page }) => {
    const empty = page.getByTestId("chart-empty");

    await expect(empty).toBeVisible();
    // And no axes behind it, which is what made this read as a failure.
    await expect(
      empty.locator("xpath=..").locator("svg.highcharts-root"),
    ).toBeHidden();
  });

  test("a failed chart says so and offers a retry", async ({ page }) => {
    const retry = page.getByTestId("chart-retry");

    await expect(retry).toBeVisible();

    // The demo's retry clears the error, which is what a real one amounts to.
    await retry.click();

    await expect(retry).toHaveCount(0);
  });

  test("the drawn charts are unaffected", async ({ page }) => {
    // The state blocks sit over the same box the chart draws into, so guarding
    // them means guarding that they stay out of the way when there is data.
    await expect(page.locator("svg.highcharts-root").first()).toBeVisible();
    expect(await page.locator("svg.highcharts-root").count()).toBeGreaterThan(
      6,
    );
  });
});
