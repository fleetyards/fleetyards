import type { Locator, Page } from "@playwright/test";
import { app, appScenario } from "../support/on-rails";
import { test, expect } from "../support/commands";

/*
 * Guards the invariants of the rebuilt Btn.
 *
 * Asserted against the ships list rather than the visual-tests page: those
 * routes are gated out of any production build, which the e2e run uses, so a
 * spec pointed at them fails everywhere except a dev server. The ships toolbar
 * happens to exercise most of what regressed anyway - a pagination BtnGroup with
 * a label segment and disabled arrows, icon-only buttons, and standalone buttons
 * to compare surfaces against. It needs the `buttons` scenario, which seeds
 * enough models for the paginator to render those arrows.
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

// The list renders a paginator above and below, so scope to one of them.
const pagination = (page: Page) => page.locator(".pagination").first();

test.describe("Buttons", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean");
    await appScenario("buttons");

    await page.goto("/ships/");
    // Waits on a disabled arrow rather than any button: it is the last part of
    // the paginator to appear, and every group assertion below depends on it.
    await expect(
      pagination(page).locator(".btn[disabled]").first(),
    ).toBeVisible();
  });

  test("the default size matches the form control height", async ({ page }) => {
    // sm is 43px like .base-input, so a button sits flush next to an input.
    const btn = page.locator(".btn--sm").first();

    expect(Math.round((await box(btn)).height)).toBe(43);
  });

  test("an icon-only button stays square", async ({ page }) => {
    // Without a min-width it collapses to the width of its glyph.
    const btn = pagination(page).locator(".btn--grouped").nth(1);
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
    const member = pagination(page).locator(".btn--grouped").first();

    expect(await style(member, "background-color")).toBe(
      await style(standalone, "background-color"),
    );
  });

  test("a group's label segment matches its members", async ({ page }) => {
    // The paginator puts its page indicator in a bare span; without a surface of
    // its own the group's track showed through and it read as a highlighted
    // panel rather than a segment.
    const label = pagination(page).locator(".btn-group__track > span").first();
    const member = pagination(page).locator(".btn--grouped").first();

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
    const member = pagination(page).locator(".btn--grouped").first();

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
    const disabled = pagination(page).locator(".btn[disabled]").first();
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
    const disabled = pagination(page).locator(".btn[disabled]").first();

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

  test("the toolbar keeps a gap to the content below", async ({ page }) => {
    // Btn no longer ships margin-bottom, so the toolbar owns this spacing.
    const actions = page.locator(".filtered-list__actions").first();

    expect(await style(actions, "margin-bottom")).not.toBe("0px");
  });
});
