import { test, expect } from "../support/commands";
import { app, appScenario } from "../support/on-rails";

test.describe("Header search", () => {
  test.beforeEach(async () => {
    await app("clean");
    await appScenario("fleet_directory");
  });

  test("answers in the header of a page that has no search of its own", async ({
    page,
  }) => {
    await page.goto("/fleets/directory/");

    const field = page.locator("#header-left input[name='search']");
    await field.fill("nothing like this");

    await expect(page.getByTestId("home-search-empty")).toBeVisible();
  });

  test("offers a guest the catalogue alone", async ({ page }) => {
    await page.goto("/fleets/directory/");

    await page.locator("#header-left input[name='search']").fill("deep");

    await expect(page.getByTestId("home-search-results")).toBeVisible();
    await expect(page.getByTestId("home-search-scope")).toHaveCount(0);
  });

  test("steps aside on the login page", async ({ page }) => {
    await page.goto("/login/");

    await expect(page.locator("input[name='login']")).toBeVisible();
    await expect(page.locator("#header-left form[role='search']")).toHaveCount(
      0,
    );
  });

  test("fits a phone without pushing the page sideways", async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 800 });
    await page.goto("/fleets/directory/");

    await expect(
      page.locator("#header-left input[name='search']"),
    ).toBeVisible();
    expect(
      await page.evaluate(
        () => document.documentElement.scrollWidth <= window.innerWidth,
      ),
    ).toBe(true);
  });
});
