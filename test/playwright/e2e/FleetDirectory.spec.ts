import { test, expect } from "../support/commands";
import { app, appScenario } from "../support/on-rails";

test.describe("Fleet directory", () => {
  test.beforeEach(async () => {
    await app("clean");
    await appScenario("fleet_directory");
  });

  test("/fleets/ opens the directory once it is rolled out", async ({
    page,
  }) => {
    await page.goto("/fleets/");

    await expect(page).toHaveURL(/\/fleets\/directory\//);
    await expect(page.getByTestId("fleet-directory-card")).toHaveCount(2);
  });

  test("finds a fleet by its SID and opens its page", async ({ page }) => {
    await page.goto("/fleets/directory/");

    await page.locator("input[name='search']").fill("digdeep");

    await expect(page.getByTestId("fleet-directory-card")).toHaveCount(1);
    await expect(page.getByTestId("fleet-directory-card")).toContainText(
      "Deep Diggers",
    );

    await page
      .getByTestId("fleet-directory-card")
      .getByRole("link", { name: /Deep Diggers/ })
      .click();

    await expect(page).toHaveURL(/\/fleets\/diggers\//);
  });

  test("shows the same fleets as rows", async ({ page }) => {
    await page.goto("/fleets/directory/");

    await page.getByTestId("fleet-directory-display-options").click();
    await page.getByTestId("fleet-directory-list-view").click();

    await expect(page.getByTestId("fleet-directory-row")).toHaveCount(2);
  });
});
