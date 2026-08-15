import { test, expect } from "../support/commands";
import { app, appFactories, appScenario } from "../support/on-rails";

test.describe("Hangar Inventories", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean");
    await appScenario("hangar_inventories");

    await appFactories([
      ["create", "user", { username: "inventories", password: "password" }],
    ]);

    await page.goto("/login/");

    await page.locator("input[name='login']").fill("inventories");
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

    // Only the name is filled: the form defaults the category to commodity and
    // the quantity to 1, which is enough for the entry to post.
    const entryCreated = page.waitForResponse(
      (response) =>
        response.url().includes("/items") &&
        response.request().method() === "POST",
    );

    await page.getByTestId("inventory-deposit").click();
    await page.getByTestId("modal").waitFor({ state: "visible" });

    await page.getByTestId("input-name").fill("Titanium");
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
