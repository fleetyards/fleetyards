import type { Page } from "@playwright/test";
import { test, expect } from "../support/commands";
import { app, appScenario } from "../support/on-rails";

const login = async (page: Page, username: string) => {
  await page.goto("/login/");

  await page.locator("input[name='login']").fill(username);
  await page.locator("input[name='password']").fill("password");

  const sessionCreated = page.waitForResponse(
    (response) =>
      response.url().includes("/api/v1/sessions") &&
      response.request().method() === "POST",
  );

  await page.getByTestId("submit-login").click();

  await sessionCreated;

  await expect(page).not.toHaveURL(/\/login/);
};

test.describe("Fleet Shopping Lists", () => {
  test.beforeEach(async () => {
    await app("clean");
    await appScenario("fleet_shopping_lists");
  });

  test("an officer publishes one of their lists to the fleet", async ({
    page,
  }) => {
    await login(page, "quartermaster");

    await page.goto("/fleets/mercguild/shopping-lists/");

    await page.getByTestId("fleet-shopping-list-publish").click();

    const source = page.getByTestId("base-select-cartId");
    await source.getByTestId("base-select-title").click();
    await source.getByRole("option", { name: /Uniform/ }).click();

    await expect(
      page.getByTestId("fleet-shopping-list-name").locator("input"),
    ).toHaveValue("Uniform");

    const published = page.waitForResponse(
      (response) =>
        response.url().includes("/shopping-lists") &&
        response.request().method() === "POST",
    );
    await page.getByTestId("fleet-shopping-list-submit").click();
    await published;

    const uniform = page
      .getByTestId("fleet-shopping-list")
      .filter({ hasText: "Uniform" });

    await expect(uniform).toContainText("2");
  });

  test("a member copies a fleet list into a new list of their own", async ({
    page,
  }) => {
    await login(page, "recruit");

    await page.goto("/fleets/mercguild/shopping-lists/");

    const kit = page
      .getByTestId("fleet-shopping-list")
      .filter({ hasText: "Standard kit" });

    await kit.getByTestId("fleet-shopping-list-toggle").click();
    await expect(kit.getByTestId("fleet-shopping-list-line")).toContainText(
      "Adiva Jacket",
    );
    await expect(kit.getByTestId("fleet-shopping-list-total")).toContainText(
      "210",
    );

    await expect(kit.getByTestId("fleet-shopping-list-menu")).toHaveCount(0);

    const copied = page.waitForResponse(
      (response) =>
        response.url().includes("/copy") &&
        response.request().method() === "POST",
    );
    await kit.getByTestId("fleet-shopping-list-copy").click();
    await page.getByTestId("fleet-shopping-list-copy-new").click();
    await copied;

    await page.goto("/cart/");

    await expect(page.getByTestId("cart-total")).toContainText("210");
    await expect(page.getByTestId("cart-stop")).toContainText("Everus Harbor");
  });
});
