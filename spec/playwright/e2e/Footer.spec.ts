import { test, expect } from "../support/commands";

test.describe("Footer", () => {
  test("Loads", async ({ page, acceptCookie }) => {
    await page.goto("/");

    await acceptCookie.accept();

    await expect(page.getByTestId("app-footer")).toBeVisible();
  });
});
