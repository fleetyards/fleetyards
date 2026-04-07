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

    await page.getByText("Fleet Settings").click();

    await expect(page).toHaveURL(/\/settings\/fleet\//);

    await page.getByTestId("fleet-delete").click();

    await page.getByTestId("confirm-dialog").waitFor({ state: "visible" });
    await page.getByTestId("confirm-ok").click();

    await page.waitForTimeout(500);

    await notification.success("Your Fleet has been destroyed.");
  });

  test("update fleet settings", async ({ page, nav, notification }) => {
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

    const fleetSettingsTab = page.locator("a", { hasText: "Fleet Settings" });

    await fleetSettingsTab.waitFor({ state: "visible" });
    await fleetSettingsTab.click();

    await expect(page).toHaveURL(/\/settings\/fleet\//);

    await page
      .locator("textarea[name='description']")
      .waitFor({ state: "visible" });

    await page.locator("textarea[name='description']").fill("test");

    const responsePromise = page.waitForResponse(
      (resp) =>
        resp.url().includes("/fleets/") && resp.request().method() === "PUT",
    );

    await page.getByTestId("submit-form").click();

    const response = await responsePromise;
    const body = await response.text();
    expect(response.status(), `Response body: ${body}`).toBe(200);

    await notification.success("Settings saved.");
  });
});
