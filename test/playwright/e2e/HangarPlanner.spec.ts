import { test, expect } from "../support/commands";
import type { Page } from "@playwright/test";
import { app, appScenario } from "../support/on-rails";

const pickOption = async (
  page: Page,
  name: string,
  option: string,
) => {
  await page
    .getByTestId(`base-select-${name}`)
    .getByTestId("base-select-title")
    .click();
  await page.getByRole("option", { name: option, exact: true }).click();
};

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

    await pickOption(page, "startKind", "Kept from hangar");
    await pickOption(page, "sourceVehicleId", "Cutlass Black");
    await page.getByTestId("hangar-plan-route-add-step").click();
    await pickOption(page, "steps.0.sourceKind", "My RSI hangar");
    await pickOption(
      page,
      "steps.0.hangarPledgeItemId",
      "Upgrade - Cutlass Black To Carrack",
    );

    const routeCreated = page.waitForResponse(
      (response) =>
        response.url().includes("/acquisitions") &&
        response.request().method() === "POST",
    );
    await page.getByTestId("hangar-plan-route-save").click();
    await routeCreated;
    await page.getByTestId("modal").waitFor({ state: "hidden" });

    await expect(page.getByTestId("hangar-plan-route")).toContainText(
      "Cutlass Black → Carrack",
    );

    // The Aurora is not needed, so it is melted for store credit.
    await page.getByTestId("hangar-plan-add-melt").click();
    await page.getByTestId("modal").waitFor({ state: "visible" });
    await pickOption(page, "vehicleId", "Aurora MR");

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

    const statuses = page.getByTestId("hangar-plan-vehicle-status");
    await expect(statuses.filter({ hasText: "Cutlass Black" })).toContainText(
      "Upgraded",
    );
    await expect(statuses.filter({ hasText: "Aurora MR" })).toContainText(
      "Melted",
    );
  });
});
