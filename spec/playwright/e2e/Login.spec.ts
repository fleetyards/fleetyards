import { app, appFactories } from "../support/on-rails";
import { test, expect } from "../support/commands";

test.describe("Login", () => {
  test.beforeEach(async ({ page, acceptCookie }) => {
    await app("clean");

    await page.goto("/");

    await acceptCookie.accept();
  });

  test("Success", async ({ page, nav }) => {
    await nav.click("login");

    await expect(page).toHaveURL(/\/login/);

    await appFactories([
      ["create", "user", { username: "test", password: "password" }],
    ]);

    await page.locator("input[name='login']").fill("test");
    await page.locator("input[name='password']").fill("password");

    await page.getByTestId("submit-login").click();

    await expect(page.locator(".user-menu")).toContainText("test");

    await nav.click("logout");

    await expect(page.getByTestId("nav-login")).toBeVisible();
  });

  test("Shows Alert when using invalid credentials", async ({
    page,
    nav,
    notification,
  }) => {
    await nav.click("login");

    await expect(page).toHaveURL(/\/login/);

    await page.locator("input[name='login']").fill("invalidUsername");
    await page.locator("input[name='password']").fill("invalidPassword");

    await page.getByTestId("submit-login").click();

    await notification.alert("Invalid email or password");
  });

  test("Redirects to login when visiting restricted page", async ({ page }) => {
    await appFactories([
      ["create", "user", { username: "test", password: "password" }],
    ]);

    await page.goto("/settings");

    await expect(page).toHaveURL(/\/login/);

    await page.locator("input[name='login']").fill("test");
    await page.locator("input[name='password']").fill("password");

    await page.getByTestId("submit-login").click();

    await expect(page).toHaveURL(/\/settings/);
  });
});
