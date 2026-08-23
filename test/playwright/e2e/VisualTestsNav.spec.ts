import { test, expect } from "../support/commands";

/*
 * A new demo page needs four separate edits - the route, a nav entry, and keys
 * in en/{headlines,nav,title}.json - and forgetting the nav entry leaves a page
 * that exists but cannot be found. So the invariant worth guarding is that every
 * route is reachable from the nav, not that the nav matches some other list.
 *
 * The routes are listed here rather than imported: routes.ts pulls in .vue
 * components, which this runner cannot resolve.
 */

const GROUPED = {
  foundations: ["typography", "panels", "buttons", "chips", "media"],
  data: ["tables", "lists", "metrics", "charts"],
  feedback: ["states", "notifications", "support-hint", "sync-modal"],
};

// Pages that carry no group: a group of one is an entry wearing a folder.
const TOP_LEVEL = ["forms", "events"];

const ALL = [...Object.values(GROUPED).flat(), ...TOP_LEVEL];

test.describe("Visual tests nav", () => {
  test("every demo page has exactly one nav link", async ({ page }) => {
    await page.goto("/visual-tests/typography/");
    await expect(page.locator(".visual-tests")).toBeVisible();

    // Open every group so the submenu links are in the DOM.
    for (const group of Object.keys(GROUPED)) {
      await page
        .locator(`[data-test='nav-visual-tests-${group}-menu'] button`)
        .first()
        .click();
    }

    for (const name of ALL) {
      await expect(
        page.locator(`a[href$='/visual-tests/${name}/']`),
        `nav link for ${name}`,
      ).toHaveCount(1);
    }
  });

  test("a group is marked active while one of its pages is open", async ({
    page,
  }) => {
    // This is what tells you where you are once the submenu has closed again.
    for (const [group, members] of Object.entries(GROUPED)) {
      await page.goto(`/visual-tests/${members[0]}/`);

      const item = page.locator(`[data-test='nav-visual-tests-${group}-menu']`);
      await expect(item, `${group} in the nav`).toBeVisible();
      await expect(item, `${group} active`).toHaveClass(
        /nav-item__sub-menu--active/,
      );
    }
  });

  test("a group is not marked active from another group's page", async ({
    page,
  }) => {
    await page.goto("/visual-tests/charts/");

    await expect(
      page.locator("[data-test='nav-visual-tests-data-menu']"),
    ).toHaveClass(/nav-item__sub-menu--active/);
    await expect(
      page.locator("[data-test='nav-visual-tests-feedback-menu']"),
    ).not.toHaveClass(/nav-item__sub-menu--active/);
  });
});
