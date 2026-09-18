import { test, expect } from "../support/commands";
import { app, appScenario } from "../support/on-rails";

test.describe("Images", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean");
    await appScenario("images");

    await page.goto("/");
  });

  test("Loads", async ({ page, nav }) => {
    await nav.click("images");

    await expect(page).toHaveURL(/\/images/);

    // The grid rather than the whole list: `images-list` is on the
    // `FilteredList` root, so this counted the paginator and the sort chips as
    // images too.
    const images = page.getByTestId("images-grid").locator("a");
    await expect(images).toHaveCount(20);
  });
});
