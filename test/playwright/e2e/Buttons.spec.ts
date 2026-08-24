import type { Locator, Page } from "@playwright/test";
import { app, appScenario } from "../support/on-rails";
import { test, expect } from "../support/commands";

/*
 * Guards the invariants of the rebuilt Btn.
 *
 * Asserted against visual-tests/buttons.vue, which renders every shape these
 * assertions need and needs no seeded data to do it. That page was previously
 * unreachable here: the gate stripped it whenever Vite built rather than served,
 * and CI precompiles, so a spec pointed at it passed locally and failed in CI.
 * The gate is on the Vite mode now, which is `test` for the e2e build.
 *
 * The toolbar assertion at the bottom stays on the ships list - it is about a
 * page owning the spacing Btn stopped shipping, so a demo page cannot show it.
 *
 * Computed style rather than pixel snapshots: each of these was an invariant
 * violation, and an assertion names the broken invariant where an image diff
 * only says something moved. Snapshots would also need baselines built inside
 * the e2e container, since Playwright keys them per platform.
 */

const style = (locator: Locator, property: string) =>
  locator.evaluate(
    (el, prop) => getComputedStyle(el).getPropertyValue(prop),
    property,
  );

const box = async (locator: Locator) => {
  const b = await locator.boundingBox();
  if (!b) throw new Error("element has no bounding box");
  return b;
};

// The group holding a label segment and a disabled arrow - the paginator's
// shape, which is what every group assertion below is really about.
const group = (page: Page) => page.getByTestId("group-with-label");

test.describe("Buttons", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/visual-tests/buttons/");
    // Waits on the disabled arrow rather than any button: every group assertion
    // below depends on it.
    await expect(group(page).locator(".btn[disabled]").first()).toBeVisible();
  });

  test("the default size matches the form control height", async ({ page }) => {
    // sm is 43px like .base-input, so a button sits flush next to an input.
    const btn = page.locator(".btn--sm").first();

    expect(Math.round((await box(btn)).height)).toBe(43);
  });

  test("an icon-only button stays square", async ({ page }) => {
    // Without a min-width it collapses to the width of its glyph.
    const btn = group(page).locator(".btn--grouped").nth(1);
    const { width, height } = await box(btn);

    expect(Math.round(width)).toBe(Math.round(height));
  });

  test("buttons carry no margin of their own", async ({ page }) => {
    // Spacing belongs to the container; `inline` existed only to cancel this.
    const btn = page.locator(".btn").first();

    for (const side of ["top", "right", "bottom", "left"]) {
      expect(await style(btn, `margin-${side}`)).toBe("0px");
    }
  });

  test("end-caps are present on a standalone button", async ({ page }) => {
    const btn = page.locator(".btn--solid:not(.btn--grouped)").first();

    const caps = await btn.evaluate((el) =>
      ["::before", "::after"].map((pseudo) => {
        const cs = getComputedStyle(el, pseudo);
        return { content: cs.content, height: cs.height };
      }),
    );

    for (const cap of caps) {
      expect(cap.content).not.toBe("none");
      expect(cap.height).toBe("2px");
    }
  });

  test("a group shares the standalone button surface", async ({ page }) => {
    // A group used an opaque fill while standalone buttons are translucent, so
    // it read as a different material against a bright backdrop.
    const standalone = page.locator(".btn--solid:not(.btn--grouped)").first();
    const member = group(page).locator(".btn--grouped").first();

    expect(await style(member, "background-color")).toBe(
      await style(standalone, "background-color"),
    );
  });

  test("a group's label segment matches its members", async ({ page }) => {
    // The paginator puts its page indicator in a bare span; without a surface of
    // its own the group's track showed through and it read as a highlighted
    // panel rather than a segment.
    const label = group(page).locator(".btn-group__track > span").first();
    const member = group(page).locator(".btn--grouped").first();

    await expect(label).toBeVisible();
    expect(await style(label, "background-color")).toBe(
      await style(member, "background-color"),
    );
    expect(Math.round((await box(label)).height)).toBe(
      Math.round((await box(member)).height),
    );
  });

  test("group members carry no chrome of their own", async ({ page }) => {
    // The container draws one border and one pair of caps for the whole control.
    const member = group(page).locator(".btn--grouped").first();

    expect(await style(member, "border-top-width")).toBe("0px");
    expect(await style(member, "border-radius")).toBe("0px");

    const capContent = await member.evaluate(
      (el) => getComputedStyle(el, "::before").content,
    );
    expect(capContent).toBe("none");
  });

  test("a disabled group member dims its content, not the element", async ({
    page,
  }) => {
    // Element-wide opacity turns an opaque surface translucent, so a disabled
    // pagination arrow read as *lighter* than its enabled siblings.
    const disabled = group(page).locator(".btn[disabled]").first();
    await expect(disabled).toBeVisible();

    expect(await style(disabled, "opacity")).toBe("1");
    expect(
      Number(await style(disabled.locator(".btn__content"), "opacity")),
    ).toBeLessThan(1);
  });

  test("a disabled paginator arrow is a real disabled button", async ({
    page,
  }) => {
    // `disabled` has no effect on <a>, so a disabled link button used to stay
    // clickable and focusable. Anything disabled renders as a <button>.
    const disabled = group(page).locator(".btn[disabled]").first();

    expect(await disabled.evaluate((el) => el.tagName)).toBe("BUTTON");
    await expect(disabled).toBeDisabled();
  });

  test("a focus ring is defined for keyboard focus", async ({ page }) => {
    // The old component set outline:none with no replacement, so keyboard focus
    // was invisible. Asserted against the stylesheet rather than by focusing:
    // :focus-visible is driven by a browser heuristic that a programmatic
    // .focus() does not satisfy, so the live check reports no outline even when
    // the rule is correct.
    const hasFocusRing = await page.evaluate(() =>
      [...document.styleSheets].some((sheet) => {
        try {
          return [...sheet.cssRules].some((rule) => {
            const selector = (rule as CSSStyleRule).selectorText;
            return (
              !!selector &&
              selector.includes(".btn") &&
              selector.includes(":focus-visible") &&
              /outline/.test(rule.cssText)
            );
          });
        } catch {
          // Cross-origin stylesheet, not ours.
          return false;
        }
      }),
    );

    expect(hasFocusRing).toBe(true);
  });
});

test.describe("PrimaryAction", () => {
  /*
   * The hangar's one obvious next step. It was a `div` with a click handler in a
   * circle, so it could not be tabbed to, showed no focus ring and reported no
   * role - the same defects Btn was rebuilt to fix, in the control that matters
   * most on the page.
   */
  test.beforeEach(async ({ page }) => {
    await page.goto("/visual-tests/buttons/");
    await page.getByTestId("toggle-primary-action").click();
  });

  test("is a real button, reachable from the keyboard", async ({ page }) => {
    const action = page.getByTestId("primary-action");

    await expect(action).toBeVisible();
    expect(await action.evaluate((el) => el.tagName)).toBe("BUTTON");

    await action.focus();
    await expect(action).toBeFocused();

    await page.keyboard.press("Enter");

    await expect(page.getByTestId("primary-action-clicks")).toContainText("1×");
  });

  test("carries the button surface, not a circle of its own", async ({
    page,
  }) => {
    // It borrows Btn's chrome now, so it has the end-caps every other button
    // has and none of the retired panel's border tokens.
    const caps = await page
      .getByTestId("primary-action")
      .evaluate((el) =>
        ["::before", "::after"].map(
          (pseudo) => getComputedStyle(el, pseudo).content,
        ),
      );

    for (const cap of caps) {
      expect(cap).not.toBe("none");
    }

    const radius = await page
      .getByTestId("primary-action")
      .evaluate((el) => getComputedStyle(el).borderTopLeftRadius);
    expect(radius).not.toBe("50%");
  });
});

test.describe("Buttons in a real toolbar", () => {
  test("the toolbar keeps a gap to the content below", async ({ page }) => {
    // Btn no longer ships margin-bottom, so the toolbar owns this spacing.
    // Only a real list has one, hence the seeded page.
    await app("clean");
    await appScenario("buttons");

    await page.goto("/ships/");

    const actions = page.locator(".filtered-list__actions").first();
    await expect(actions).toBeVisible();

    expect(await style(actions, "margin-bottom")).not.toBe("0px");
  });
});
