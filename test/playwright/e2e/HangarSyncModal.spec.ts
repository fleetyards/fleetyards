import { test, expect } from "../support/commands";

/*
 * The sync modal's start screen only appears once the browser extension has
 * answered, so it is out of reach in a test except through the demo page, which
 * stands in for the extension and opens the real modal.
 *
 * The options worth guarding are the ones with a default that matters: the
 * bundled snub craft toggle is on -- leaving those ships out has to be a
 * decision -- and the unmatched action is the wishlist move every sync did
 * before the choice existed. Both are kept, so somebody who wants something
 * else does not have to say so before every sync.
 */

type Page = import("@playwright/test").Page;

const TOGGLE = "toggle-syncAddBundledVehicles";
const ACTION_SELECT = "base-select-syncUnmatchedVehiclesAction";

const input = (page: Page) => page.getByTestId(TOGGLE);

// The input carries the state but is `opacity: 0` behind the switch; the label
// is what anyone actually clicks.
const control = (page: Page) =>
  page.locator(`.form-toggle:has([data-test='${TOGGLE}']) label`);

const chooseAction = async (page: Page, label: string) => {
  await page
    .getByTestId(ACTION_SELECT)
    .getByTestId("base-select-title")
    .click();
  await page.getByRole("option", { name: label, exact: true }).click();
};

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

  test("keeps the bundled choice for the next sync", async ({ page }) => {
    await openStartScreen(page);

    await control(page).click();
    await expect(input(page)).not.toBeChecked();

    // Reopened from a fresh load, not just a second click on the card: the
    // choice has to outlive the page, or it is only remembered for as long as
    // nobody leaves the hangar.
    await openStartScreen(page);

    await expect(input(page)).not.toBeChecked();
  });

  test("moves what it does not find to the wishlist by default", async ({
    page,
  }) => {
    await openStartScreen(page);

    await expect(
      page.getByTestId(ACTION_SELECT).getByTestId("base-select-title"),
    ).toContainText("Move them to the wishlist");
  });

  // The group picker is the one option that needs a second answer, so it is the
  // one that can be half-made. It appears with the action and disappears again.
  test("asks for a group only when that is the action", async ({ page }) => {
    await openStartScreen(page);

    const groupPicker = page.getByTestId(
      "base-select-syncUnmatchedHangarGroupId",
    );

    await expect(groupPicker).toBeHidden();

    await chooseAction(page, "File them into a group");

    await expect(groupPicker).toBeVisible();

    await chooseAction(page, "Delete them");

    await expect(groupPicker).toBeHidden();
  });

  test("keeps the chosen action for the next sync", async ({ page }) => {
    await openStartScreen(page);

    await chooseAction(page, "Delete them");

    // Reopened from a fresh load, for the same reason as the toggle above.
    await openStartScreen(page);

    await expect(
      page.getByTestId(ACTION_SELECT).getByTestId("base-select-title"),
    ).toContainText("Delete them");
  });
});
