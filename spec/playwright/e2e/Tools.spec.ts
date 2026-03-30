import { app, appScenario } from "../support/on-rails";
import { test, expect } from "../support/commands";

test.describe("Tools Index", () => {
  test.beforeEach(async ({ page, acceptCookie }) => {
    await app("clean");
    await appScenario("tools");

    await page.goto("/tools/");

    await acceptCookie.accept();
  });

  test("Loads the tools page", async ({ page }) => {
    await expect(page).toHaveURL(/\/tools/);
    await expect(page.locator("h1")).toBeVisible();
  });

  test("Shows tool cards", async ({ page }) => {
    const toolCards = page.getByTestId("tool-card-link");
    await expect(toolCards.first()).toBeVisible();

    // Verify some known tools are present
    await expect(page.getByText("Verse Guide")).toBeVisible();
    await expect(page.getByText("Erkul")).toBeVisible();
    await expect(page.getByText("UEX Corp")).toBeVisible();
  });

  test("Shows disabled banner for unavailable tools", async ({ page }) => {
    const disabledBanner = page.getByTestId("tool-card-banner");
    await expect(disabledBanner).toBeVisible();
  });

  test("Tool cards have external links", async ({ page }) => {
    const toolLinks = page.getByTestId("tool-card-link");
    await expect(toolLinks.first()).toBeVisible();
  });
});
