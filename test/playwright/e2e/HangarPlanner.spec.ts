import { test, expect } from "../support/commands";
import { app, appScenario } from "../support/on-rails";

test.describe("Hangar Planner", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean");
    await appScenario("hangar_planner");

    await page.goto("/login/");

    await page.locator("input[name='login']").fill("planner");
    await page.locator("input[name='password']").fill("password");

    const sessionCreated = page.waitForResponse(
      (response) =>
        response.url().includes("/api/v1/sessions") &&
        response.request().method() === "POST",
    );

    await page.getByTestId("submit-login").click();

    await sessionCreated;

    await expect(page).not.toHaveURL(/\/login/);
  });

  test("plans a route with an owned upgrade and a melt", async ({ page }) => {
    await page.goto("/hangar/plans/");

    await page
      .getByTestId("hangar-plan-card")
      .getByRole("link", { name: "Endgame" })
      .click();

    await expect(page).toHaveURL(/\/hangar\/plans\/[0-9a-f-]+\//);

    const summary = page.getByTestId("hangar-plan-summary");
    await expect(summary).toContainText("1 ship without a route");

    // The Cutlass in the hangar becomes the Carrack through the upgrade the
    // RSI hangar already holds, so the route costs nothing more.
    await page.getByTestId("hangar-plan-add-route").click();
    await page.getByTestId("modal").waitFor({ state: "visible" });

    const modal = page.getByTestId("modal");
    await modal.getByTestId("hangar-plan-route-start-owned").click();
    await modal
      .getByTestId("pick-list-sourceVehicleId")
      .getByRole("button", { name: /Cutlass Black/ })
      .click();

    // The step opens on the RSI hangar, which holds an upgrade from the Cutlass.
    await modal
      .getByTestId("pick-list-steps.0.upgrade")
      .getByRole("button", { name: /Carrack/ })
      .click();
    await expect(modal.getByTestId("hangar-plan-route-preview")).toContainText(
      "The route ends on the Carrack.",
    );

    const routeCreated = page.waitForResponse(
      (response) =>
        response.url().includes("/acquisitions") &&
        response.request().method() === "POST",
    );
    await page.getByTestId("hangar-plan-route-save").click();
    await routeCreated;
    await page.getByTestId("modal").waitFor({ state: "hidden" });

    const route = page.getByTestId("hangar-plan-route");
    await expect(route).toContainText("Cutlass Black");
    await expect(route).toContainText("Carrack");
    await expect(route).toContainText("My RSI hangar");

    // The Aurora is not needed, so it is melted for store credit.
    await page.getByTestId("hangar-plan-add-melt").click();
    await page.getByTestId("modal").waitFor({ state: "visible" });
    await page
      .getByTestId("modal")
      .getByTestId("pick-list-vehicleId")
      .getByRole("button", { name: /Aurora MR/ })
      .click();

    const meltCreated = page.waitForResponse(
      (response) =>
        response.url().includes("/melts") &&
        response.request().method() === "POST",
    );
    await page.getByTestId("hangar-plan-melt-save").click();
    await meltCreated;
    await page.getByTestId("modal").waitFor({ state: "hidden" });

    await expect(summary).toContainText("Every ship has a route and a price.");
    await expect(
      page.getByTestId("hangar-plan-summary-meltCredit"),
    ).toContainText("30");

    await page.getByTestId("hangar-plan-compare-hangar").click();
    await expect(page).toHaveURL(/\/hangar\/plans\/[0-9a-f-]+\/hangar\//);

    const statuses = page.getByTestId("hangar-plan-vehicle-status");
    await expect(statuses.filter({ hasText: "Cutlass Black" })).toContainText(
      "Upgraded",
    );
    await expect(statuses.filter({ hasText: "Aurora MR" })).toContainText(
      "Melted",
    );
  });
});
