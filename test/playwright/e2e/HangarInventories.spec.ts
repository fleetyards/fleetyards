import { test, expect } from "../support/commands";
import { app, appFactories, appScenario } from "../support/on-rails";

test.describe("Hangar Inventories", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean");
    await appScenario("hangar_inventories");

    await appFactories([
      ["create", "user", { username: "quartermaster", password: "password" }],
    ]);

    await page.goto("/login/");

    await page.locator("input[name='login']").fill("quartermaster");
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

  test("Default Workflow", async ({ page }) => {
    await page.goto("/hangar/inventories/");

    const inventoryCreated = page.waitForResponse(
      (response) =>
        response.url().includes("/api/v1/hangar/inventories") &&
        response.request().method() === "POST",
    );

    await page.getByTestId("hangar-inventory-create").click();
    await page.getByTestId("modal").waitFor({ state: "visible" });

    await page.getByTestId("input-name").fill("Test Depot");
    await page.getByTestId("inventory-save").click();

    await inventoryCreated;

    await page.getByTestId("modal").waitFor({ state: "hidden" });

    // The slug the panel is keyed on comes from the name, see SlugConcern.
    const panel = page.getByTestId("inventory-panel-test-depot");

    await expect(panel).toBeVisible();

    await panel.getByTestId("panel-heading-title").locator("a").first().click();

    await expect(page).toHaveURL(/\/hangar\/inventories\/test-depot\//);

    // The goods are named in the item picker -- here as a custom item, since
    // the scenario carries no catalogue -- and the amount on the form, where a
    // resource asks for its grade as well as its quantity.
    const entryCreated = page.waitForResponse(
      (response) =>
        response.url().includes("/items") &&
        response.request().method() === "POST",
    );

    await page.getByTestId("inventory-deposit").click();
    await page.getByTestId("modal").waitFor({ state: "visible" });

    await page.getByTestId("item-picker-field-open").click();
    await page
      .getByTestId("base-select-item-picker-category")
      .getByTestId("base-select-title")
      .click();
    await page.getByRole("option", { name: "Commodity", exact: true }).click();
    await page.getByTestId("input-item-picker-search").fill("Titanium");
    await page.getByTestId("item-picker-custom").click();

    await page.getByTestId("input-quantity").fill("10");
    await page.getByTestId("input-quality").fill("500");
    await page.getByTestId("inventory-item-save").click();

    await entryCreated;

    await page.getByTestId("modal").waitFor({ state: "hidden" });

    const stockLink = page.getByRole("link", { name: "Titanium" });

    await expect(stockLink).toBeVisible();

    await stockLink.click();

    await expect(page).toHaveURL(
      /\/hangar\/inventories\/test-depot\/items\/titanium/,
    );
  });
});
