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
  "toggleButton",
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

  // The label lives inside the button on this one, so the icon has to sit
  // outside it -- anything focusable in a `<button>` is a second way to fire it.
  test("reading the button toggle's hint does not flip it", async ({ page }) => {
    const toggle = rig(page).locator(".base-toggle");
    const before = await toggle.getAttribute("class");

    await rig(page).locator(".base-toggle-field .hint-icon").click();

    expect(await toggle.getAttribute("class")).toBe(before);
  });

  // A hint read while dragging cannot live behind a hover, so the slider spends
  // the prop on a line under the rail instead.
  test("the slider states its hint in the page", async ({ page }) => {
    const rail = page.getByTestId("info-hint-slider");
    const line = rail.locator(".base-slider-field__info");

    await expect(line).toBeVisible();
    await expect(rail.locator(".hint-icon")).toHaveCount(0);

    // Described, not merely adjacent: the rail is what carries the role.
    const id = await line.getAttribute("id");
    await expect(rail.locator(".base-slider")).toHaveAttribute(
      "aria-describedby",
      id!,
    );
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
