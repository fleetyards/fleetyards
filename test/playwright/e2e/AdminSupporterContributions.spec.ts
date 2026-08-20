import { app, appScenario } from "../support/on-rails";
import { test, expect } from "../support/commands";

test.describe("Admin Supporter Contributions", () => {
  // The chart pulls in Highcharts, which the dev server transforms on first
  // request to this route.
  test.slow();

  test.beforeEach(async ({ page }) => {
    await app("clean");
    await appScenario("admin_supporter_contributions");

    await page.goto("/admin/login/");
    await page.locator("input[name='login']").fill("admin_supporters");
    await page.locator("input[name='password']").fill("password123");
    await page.getByTestId("submit-login").click();

    await expect(page).toHaveURL(/\/admin\/?$/);
  });

  test("Renders the monthly contributions chart against the funding goal", async ({
    page,
  }) => {
    const payloadPromise = page.waitForResponse(
      (response) =>
        response.url().includes("/supporter-contributions/per-month") &&
        response.status() === 200,
    );

    await page.goto("/admin/supporter-contributions/");

    // The scenario leaves two contributions active this month worth EUR 75.00
    // against a EUR 90.00 goal, and a recurring one spanning earlier months.
    const payload = await (await payloadPromise).json();

    expect(payload.currency).toBe("EUR");
    expect(payload.items).toHaveLength(12);
    expect(payload.items.at(-1)).toMatchObject({
      amountCents: 7500,
      goalAmountCents: 9000,
      count: 2,
    });
    // Three months back both recurring contributions overlap.
    expect(payload.items.at(-4)).toMatchObject({
      amountCents: 3500,
      goalAmountCents: 9000,
      count: 2,
    });
    expect(payload.items.at(0)).toMatchObject({ amountCents: 0, count: 0 });

    const chart = page.getByTestId("supporter-contributions-monthly-chart");

    await expect(chart).toBeVisible({ timeout: 60_000 });
    await expect(chart.locator("svg.highcharts-root")).toBeVisible();

    // One column per month for the contributions, plus a spline for the goal.
    // Highcharts draws columns as paths, so counting `rect`s would only find
    // the legend swatch.
    await expect(
      chart.locator(".highcharts-column-series > path"),
    ).toHaveCount(12);
    // A flat goal line has a zero-height box, so Playwright reads it as hidden.
    await expect(
      chart.locator(".highcharts-spline-series path.highcharts-graph").first(),
    ).toBeAttached();

    // Twelve months on the category axis, and money on the value axis.
    await expect(chart.locator(".highcharts-xaxis-labels text")).toHaveCount(12);
    await expect(
      chart.locator(".highcharts-yaxis-labels text").first(),
    ).toContainText("€");

    await expect(chart.getByText("Contributions", { exact: true })).toBeVisible();
    await expect(chart.getByText("Goal", { exact: true })).toBeVisible();
  });
});
