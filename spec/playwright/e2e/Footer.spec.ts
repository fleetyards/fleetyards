import { test, expect } from "../support/commands";

test.describe("Footer", () => {
  test("Loads", async ({ page }) => {
    await page.goto("/");

    await expect(page.getByTestId("app-footer")).toBeVisible();
  });
});
