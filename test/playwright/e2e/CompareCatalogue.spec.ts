import { app, appScenario } from "../support/on-rails";
import { test, expect } from "../support/commands";

test.describe("Compare components", () => {
  test.beforeEach(async () => {
    await app("clean");
    await appScenario("compare_catalogue");
  });

  test("starts a comparison from a component's page", async ({ page }) => {
    await page.goto("/catalogue/components/palisade/");

    await page.getByTestId("compare").click();

    await expect(page).toHaveURL(
      /\/compare\/components\/\?components%5B%5D=palisade/,
    );
    await expect(
      page.locator(".compare-table__name").getByText("Palisade"),
    ).toBeVisible();
  });

  test("offers only the category already compared", async ({ page }) => {
    await page.goto("/compare/components/?components[]=palisade");

    await page.getByTestId("compare-add-items").click();

    const rows = page.locator(".item-picker-row");
    await expect(rows.getByText("Rampart")).toBeVisible();
    await expect(rows.getByText("Atlas")).toHaveCount(0);

    // The row is covered by its pick button, which is what takes the click.
    await rows
      .filter({ hasText: "Rampart" })
      .locator(".item-picker-row__pick")
      .click();

    await expect(page).toHaveURL(/components%5B%5D=rampart/);
  });

  test("drops an item of another category from a shared link", async ({
    page,
  }) => {
    await page.goto(
      "/compare/components/?components[]=palisade&components[]=atlas",
    );

    await expect(page.getByText(/Removed Atlas/)).toBeVisible();
    await expect(page).not.toHaveURL(/atlas/);
  });
});
