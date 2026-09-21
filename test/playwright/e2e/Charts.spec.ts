import { test, expect } from "../support/commands";

/*
 * The two states a chart cannot draw itself out of. Both used to render an empty
 * box: the failure case drew nothing at all, and the no-data case was left to
 * Highcharts, which put up a bare pair of axes that reads as a chart that broke.
 *
 * Asserted against visual-tests/charts/, which drives every state from a
 * hand-built asyncStatus and needs no query behind it.
 *
 * Each chart is addressed by its own `name` rather than by the shared state test
 * id: the page draws more than one empty chart now, and a bare `chart-empty`
 * resolves to all of them.
 */

const chart = (page: import("@playwright/test").Page, name: string) =>
  page.getByTestId(`chart-${name}`);

test.describe("Charts", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/visual-tests/charts/");
    await expect(page.locator(".visual-tests")).toBeVisible();
  });

  test("a settled chart with nothing to plot says so", async ({ page }) => {
    const empty = chart(page, "vt-empty");

    await expect(empty.getByTestId("chart-empty")).toBeVisible();
    // And no axes behind it, which is what made this read as a failure.
    await expect(empty.locator("svg.highcharts-root")).toBeHidden();
  });

  /*
   * A price history whose every point is null. Six series of nothing is as empty
   * as no series at all, but the component is handed a list rather than an empty
   * one -- left to its length it would have drawn the bare axes this whole test
   * exists to prevent.
   */
  test("a multi-series chart of nothing but gaps says so too", async ({
    page,
  }) => {
    const empty = chart(page, "vt-series-empty");

    await expect(empty.getByTestId("chart-empty")).toBeVisible();
    await expect(empty.locator("svg.highcharts-root")).toBeHidden();
  });

  test("a chart with several named series draws them all", async ({ page }) => {
    const series = chart(page, "vt-series");

    await expect(series.locator("svg.highcharts-root")).toBeVisible();
    // One path per line, and a legend to tell six of them apart.
    await expect(series.locator(".highcharts-legend-item")).toHaveCount(6);
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
