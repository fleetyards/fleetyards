import { test, expect } from "../support/commands";

/*
 * Guards what FormTabs does that a screenshot cannot show: which tab it marks
 * invalid, which it refuses to activate, and which it leaves out of the strip
 * altogether.
 *
 * Asserted against visual-tests/forms/TabsDemo.vue, which stands the component
 * in a real vee-validate form and validates up front, so the error marker is on
 * screen without anyone typing. No seeded data, so no scenario.
 *
 * Run these as CI does - CI=1, against precompiled assets. The dev server
 * transforms this route's module graph on demand and a cold graph can outrun the
 * test timeout, which reads as a hung page.goto.
 */

const tab = (page: import("@playwright/test").Page, id: string) =>
  page.getByTestId(`tab-anchor-${id}`);

test.describe("FormTabs", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/visual-tests/forms/");
    await expect(tab(page, "basic")).toBeVisible();
  });

  test("marks only the tabs whose own fields are invalid", async ({ page }) => {
    // The marker comes from matching a tab's `fields` against the form's errors,
    // so a tab is not allowed to inherit a sibling's failure.
    await expect(tab(page, "contact")).toHaveClass(/has-errors/);
    await expect(tab(page, "notes")).toHaveClass(/has-errors/);
    await expect(tab(page, "basic")).not.toHaveClass(/has-errors/);
  });

  test("a disabled tab cannot be activated", async ({ page }) => {
    const locked = tab(page, "locked");

    await expect(locked).toHaveClass(/disabled/);
    await expect(locked).toHaveAttribute("aria-disabled", "true");
    // Kept out of the tab order, so it cannot be reached by keyboard either.
    await expect(locked).toHaveAttribute("tabindex", "-1");

    await locked.click({ force: true });
    await expect(locked).not.toHaveClass(/active/);
  });

  test("a hidden tab is left out of the strip, not disabled in it", async ({
    page,
  }) => {
    await expect(tab(page, "secret")).toHaveCount(0);

    await page.getByTestId("tabs-toggle-hidden").click();

    await expect(tab(page, "secret")).toBeVisible();
    await expect(tab(page, "secret")).not.toHaveClass(/disabled/);
  });

  test("the active tab round-trips through the query string", async ({
    page,
  }) => {
    // Under its own key: the default `tab` would collide with anything else on
    // the page syncing to the URL.
    await tab(page, "notes").click();

    await expect(page).toHaveURL(/demotab=notes/);
    await expect(tab(page, "notes")).toHaveClass(/active/);

    await page.goto("/visual-tests/forms/?demotab=contact");

    await expect(tab(page, "contact")).toHaveClass(/active/);
  });
});
