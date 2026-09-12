import { test, expect } from "../support/commands";

/*
 * `info` puts a sentence beside a control's label that the label has no room
 * for. Two things about it are easy to lose and invisible in a screenshot:
 *
 * - the icon is never inside the `<label>`, because a click there is handed to
 *   the control the label points at -- on a checkbox that ticks the box;
 * - the text is repeated as the icon's own label, so the hint is not available
 *   to a pointer alone.
 *
 * Asserted against visual-tests/forms/, which carries one of every control that
 * takes the prop.
 */

type Page = import("@playwright/test").Page;

const CONTROLS = [
  "infoText",
  "infoCheckbox",
  "infoToggle",
  "infoSelect",
  "infoRadio",
];

const rig = (page: Page) => page.getByTestId("info-hints");

test.describe("Form info hints", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/visual-tests/forms/");
    await expect(rig(page)).toBeVisible();
  });

  test("every control carries one hint icon", async ({ page }) => {
    await expect(rig(page).locator(".hint-icon")).toHaveCount(CONTROLS.length);
  });

  test("the hint is readable without a pointer", async ({ page }) => {
    for (const icon of await rig(page).locator(".hint-icon").all()) {
      // Not a title attribute: the tooltip is a detached element, so the label
      // is the only thing left for anything that reads the tree.
      await expect(icon).toHaveAttribute("aria-label", /\S/);
      await expect(icon).toHaveAttribute("tabindex", "0");
    }
  });

  // The checkbox is where getting this wrong is worst: an icon inside the label
  // would toggle the box on every attempt to read its hint.
  test("reading the checkbox hint does not tick the box", async ({ page }) => {
    const checkbox = page.getByTestId("checkbox-infoCheckbox");
    const before = await checkbox.isChecked();

    await rig(page)
      .locator(".base-checkbox .hint-icon")
      .click({ force: true });

    expect(await checkbox.isChecked()).toBe(before);
  });

  test("a hint wraps instead of running off the window", async ({ page }) => {
    const icon = rig(page).locator(".base-input .hint-icon").first();
    await icon.dispatchEvent("mouseenter");

    const tooltip = page.locator("[data-tooltip]");
    await expect(tooltip).toBeVisible();

    const box = await tooltip.boundingBox();
    expect(box).not.toBeNull();
    // Capped rather than as wide as the sentence: nothing here shrinks a
    // tooltip to fit, it only slides it back inside the viewport.
    expect(box!.width).toBeLessThanOrEqual(280);
    expect(box!.height).toBeGreaterThan(30);
  });
});
