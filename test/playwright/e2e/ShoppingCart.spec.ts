import { test, expect } from "../support/commands";
import { app, appScenario } from "../support/on-rails";

test.describe("Shopping Cart", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean");
    await appScenario("shopping_cart");

    await page.goto("/login/");

    await page.locator("input[name='login']").fill("shopper");
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

  test("plans where to buy an item", async ({ page }) => {
    await page.goto("/catalogue/equipment/adiva-jacket/");

    const added = page.waitForResponse(
      (response) =>
        response.url().includes("/api/v1/cart/items") &&
        response.request().method() === "POST",
    );
    await page.getByTestId("cart-add").click();
    await added;

    await expect(page.getByTestId("cart-nav").first()).toContainText("1");

    await page.goto("/cart/");

    // The cheapest place selling it.
    const stop = page.getByTestId("cart-stop");
    await expect(stop).toHaveCount(1);
    await expect(stop).toContainText("Everus Harbor");
    await expect(page.getByTestId("cart-total")).toContainText("210");

    const updated = page.waitForResponse(
      (response) =>
        response.url().includes("/api/v1/cart/items/") &&
        response.request().method() === "PUT",
    );
    await page.getByTestId("cart-line-quantity").locator("input").fill("2");
    await updated;

    await expect(page.getByTestId("cart-total")).toContainText("420");

    const pinned = page.waitForResponse(
      (response) =>
        response.url().includes("/api/v1/cart/items/") &&
        response.request().method() === "PUT",
    );
    await page.getByTestId("cart-line-places").getByRole("button").click();
    await page.getByRole("button", { name: /Garrity Defense/ }).click();
    await pinned;

    await expect(stop).toContainText("Lorville");
    await expect(page.getByTestId("cart-total")).toContainText("500");

    await page.getByTestId("cart-clear").click();
    await page.getByTestId("confirm-ok").click();

    await expect(page.getByTestId("cart-stop")).toHaveCount(0);
  });
});
