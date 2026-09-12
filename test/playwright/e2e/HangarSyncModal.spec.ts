import { test, expect } from "../support/commands";

/*
 * The sync modal's start screen only appears once the browser extension has
 * answered, so it is out of reach in a test except through the demo page, which
 * stands in for the extension and opens the real modal.
 *
 * The option worth guarding is the bundled snub craft toggle: it is on by
 * default -- leaving those ships out has to be a decision -- and the choice is
 * kept, so somebody who does not want them does not have to say so before every
 * sync.
 */

type Page = import("@playwright/test").Page;

const TOGGLE = "toggle-syncAddBundledVehicles";

const input = (page: Page) => page.getByTestId(TOGGLE);

// The input carries the state but is `opacity: 0` behind the switch; the label
// is what anyone actually clicks.
const control = (page: Page) =>
  page.locator(`.form-toggle:has([data-test='${TOGGLE}']) label`);

const openStartScreen = async (page: Page) => {
  await page.goto("/visual-tests/sync-modal/");
  await expect(page.locator(".visual-tests")).toBeVisible();

  await page.getByTestId("open-sync-modal-start").click();
  await expect(control(page)).toBeVisible();
};

test.describe("Hangar sync modal", () => {
  test("offers the bundled snub craft option, on by default", async ({
    page,
  }) => {
    await openStartScreen(page);

    await expect(input(page)).toBeChecked();
  });

  test("keeps the choice for the next sync", async ({ page }) => {
    await openStartScreen(page);

    await control(page).click();
    await expect(input(page)).not.toBeChecked();

    // Reopened from a fresh load, not just a second click on the card: the
    // choice has to outlive the page, or it is only remembered for as long as
    // nobody leaves the hangar.
    await openStartScreen(page);

    await expect(input(page)).not.toBeChecked();
  });
});
