import { test, expect } from "../support/commands";
import { app, appScenario } from "../support/on-rails";

type Page = import("@playwright/test").Page;

const signIn = async (page: Page, login: string) => {
  await page.goto("/login/");

  await page.locator("input[name='login']").fill(login);
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

test.describe("Raffles", () => {
  test.beforeEach(async () => {
    await app("clean");
  });

  test("enters the current raffle after accepting the conditions", async ({
    page,
  }) => {
    await appScenario("raffles");
    await signIn(page, "entrant");

    await page.goto("/raffles/");
    await expect(
      page.getByRole("heading", { name: "Open Raffle" }),
    ).toBeVisible();

    await expect(page.getByTestId("raffle-conditions")).toBeVisible();
    await expect(page.getByTestId("raffle-enter")).toBeDisabled();

    await page.getByTestId("raffle-accept-conditions").locator("label").click();

    const entered = page.waitForResponse(
      (response) =>
        response.url().includes("/entry") &&
        response.request().method() === "POST",
    );
    await page.getByTestId("raffle-enter").click();
    expect((await entered).status()).toBe(201);

    await expect(page.getByTestId("raffle-withdraw")).toBeVisible();
    await expect(page.getByTestId("raffle-entrants")).toContainText("entrant");
  });

  test("the winner is told to check their mail", async ({ page }) => {
    await appScenario("raffles_won");
    await signIn(page, "winner");

    await page.goto("/raffles/");
    await expect(
      page.getByRole("heading", { name: "Won Raffle" }),
    ).toBeVisible();

    await expect(page.getByTestId("raffle-winner")).toContainText("winner");
    await expect(page.getByTestId("raffle-won")).toBeVisible();
    await expect(page.locator("body")).not.toContainText("E2E-GIFT-CODE");
  });
});
