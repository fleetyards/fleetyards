import { test, expect } from "../support/commands";
import { app, appFactories } from "../support/on-rails";

test.describe("Fleet", () => {
  test.beforeEach(async ({ page, acceptCookie }) => {
    await app("clean");

    await page.goto("/");

    await acceptCookie.accept();
  });

  test("Shows Preview only once", async ({ page, nav }) => {
    await nav.click("fleets-menu", "fleet-preview");

    await expect(page).toHaveURL(/\/fleets\/preview\//);

    await page.getByTestId("login").click();

    await expect(page).toHaveURL(/\/login/);

    await page.goto("/");

    await page.waitForTimeout(300);

    await nav.click("fleets-menu", "fleet-add");

    await expect(page).toHaveURL(/\/login/);
  });

  test("default workflow", async ({ page, nav, notification }) => {
    await nav.click("fleets-menu", "fleet-preview");

    await expect(page).toHaveURL(/\/fleets\/preview\//);

    await page.getByTestId("login").click();

    await expect(page).toHaveURL(/\/login/);

    await appFactories([
      ["create", "user", { username: "test", password: "password" }],
    ]);

    await page.locator("input[name='login']").fill("test");
    await page.locator("input[name='password']").fill("password");
    await page.getByTestId("submit-login").click();

    await expect(page).toHaveURL(/\/fleets\/add\//);

    await page.getByTestId("input-fid").fill("TestFleet1");
    await page.getByTestId("input-name").fill("Test_Fleet_1");

    await page.getByTestId("fleet-save").click();

    await expect(page).toHaveURL(/\/fleets\/testfleet1\//);

    await notification.success("Your Fleet has been created.");

    await page.waitForTimeout(500);

    await nav.click("fleet-settings");

    page.on("dialog", (dialog) => dialog.accept());
    await page.getByTestId("fleet-delete").click();

    await page.waitForTimeout(500);

    await notification.success("Your Fleet has been destroyed.");
  });
});
