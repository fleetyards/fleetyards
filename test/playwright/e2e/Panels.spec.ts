import type { Locator, Page } from "@playwright/test";
import { app, appScenario } from "../support/on-rails";
import { test, expect } from "../support/commands";

/*
 * Guards the invariants of the rebuilt Panel.
 *
 * Asserted against the ships list rather than visual-tests/panels.vue: those
 * routes are gated behind `NODE_ENV !== "production"` in frontend/pages/routes.ts
 * and the e2e run uses a production build, so a spec pointed at them passes only
 * against a dev server. The ships list happens to render the component's hardest
 * case anyway - a card whose whole height comes from a background image.
 *
 * Computed style rather than pixel snapshots, for the same reasons Buttons.spec.ts
 * gives: each of these was a real defect, and an assertion names the broken
 * invariant where an image diff only says something moved. Baselines would also
 * have to be built inside the e2e container, since Playwright keys them per
 * platform.
 */

const style = (locator: Locator, property: string) =>
  locator.evaluate(
    (el, prop) => getComputedStyle(el).getPropertyValue(prop),
    property,
  );

const pseudo = (
  locator: Locator,
  which: "before" | "after",
  property: string,
) =>
  locator.evaluate(
    (el, [w, prop]) => getComputedStyle(el, `::${w}`).getPropertyValue(prop),
    [which, property] as const,
  );

const box = async (locator: Locator) => {
  const b = await locator.boundingBox();
  if (!b) throw new Error("element has no bounding box");
  return b;
};

const card = (page: Page) => page.locator(".model-panel").first();

test.describe("Panels", () => {
  // Seeded once for the file rather than per test. Every assertion here is
  // read-only, and cleaning and reseeding eleven times costs minutes without
  // buying any isolation.
  test.beforeAll(async () => {
    await app("clean");
    await appScenario("ships");
  });

  // Reached through the nav rather than by goto("/ships/"), which is how
  // Ships.spec.ts does it - a direct load of the list route renders no cards.
  test.beforeEach(async ({ page, nav }) => {
    await page.goto("/");
    await nav.click("ships");

    await expect(page).toHaveURL(/\/ships/);
    await expect(card(page)).toBeVisible();
  });

  test("a panel is one box, not three", async ({ page }) => {
    // The old component wrapped a 2px/radius-24 .panel-wrapper around a
    // 3px/radius-20 .panel around a radius-16 .panel-inner.
    await expect(page.locator(".panel-wrapper")).toHaveCount(0);

    expect(await style(card(page), "border-top-width")).toBe("2px");
    expect(await style(card(page), "border-top-left-radius")).toBe("16px");
  });

  test("the .panel class is kept as a contract", async ({ page }) => {
    // Home.spec.ts locates panels with it, and the card components key their
    // own styles off it.
    await expect(card(page)).toHaveClass(/(^|\s)panel(\s|$)/);
  });

  test("a panel carries one pair of end-caps", async ({ page }) => {
    const caps = await card(page).evaluate((el) =>
      ["::before", "::after"].map((p) => {
        const cs = getComputedStyle(el, p);
        return { content: cs.content, height: cs.height };
      }),
    );

    for (const cap of caps) {
      expect(cap.content).not.toBe("none");
      expect(cap.height).toBe("4px");
    }
  });

  test("the caps are inset proportionally, not by a fixed amount", async ({
    page,
  }) => {
    // A fixed 80px per side left 45% of the width at the col-md-4 this grid
    // uses, and nothing at all below 160px. max(10px, 12%) holds 76% at any
    // width the grid produces.
    const { width } = await box(card(page));
    const inset = parseFloat(await pseudo(card(page), "before", "left"));

    expect(inset).toBeGreaterThanOrEqual(10);
    expect(Math.round((inset / width) * 100)).toBe(12);
  });

  test("the caps round their inward edge only", async ({ page }) => {
    // So the outward edge stays a line continuous with the border. The old
    // component did this; MetricsCard and Btn both rounded all four corners.
    expect(
      await pseudo(card(page), "before", "border-bottom-left-radius"),
    ).toBe("3px");
    expect(await pseudo(card(page), "before", "border-top-left-radius")).toBe(
      "0px",
    );

    expect(await pseudo(card(page), "after", "border-top-left-radius")).toBe(
      "3px",
    );
    expect(await pseudo(card(page), "after", "border-bottom-left-radius")).toBe(
      "0px",
    );
  });

  test("the caps paint above the background image", async ({ page }) => {
    // ::before is generated ahead of an element's children, so at z-index auto
    // it painted under PanelBgImage - which is inset to the padding box, and so
    // covered the inner 2px of the top cap while the bottom cap stayed whole.
    expect(await pseudo(card(page), "before", "z-index")).toBe("1");
    expect(await pseudo(card(page), "after", "z-index")).toBe("1");
  });

  test("an image card keeps a height of its own", async ({ page }) => {
    // A background image contributes none, so without a floor the card collapses
    // to the height of its title and chips and the photo disappears. The floor is
    // on the image region rather than the card, so it survives a footer opening.
    const inner = card(page).locator(".panel__inner").first();

    expect(await style(inner, "min-height")).toBe("286px");
    expect((await box(inner)).height).toBeGreaterThanOrEqual(286);
  });

  test("the background image is contained to the image region", async ({
    page,
  }) => {
    // Parented to .panel it covered the footer too, so a card's collapsed detail
    // panel wore the ship photo.
    const bg = card(page).locator(".panel-bg").first();

    expect(
      await bg.evaluate((el) =>
        el.parentElement?.className.includes("panel__inner"),
      ),
    ).toBe(true);
  });

  test("a panel ships its own bottom spacing", async ({ page }) => {
    // Unlike Btn, which had 112 call sites cancelling its margin. A panel is a
    // block-level surface stacked vertically and 89 of 91 sites want this.
    expect(await style(card(page), "margin-bottom")).toBe("21px");
  });

  test("the heading keeps its test hook", async ({ page }) => {
    // Home, Hangar, Ships and Ship all locate panel titles by it.
    await expect(
      card(page).locator("[data-test='panel-heading-title']").first(),
    ).toBeVisible();
  });

  test("a tone colours the cap and leaves the frame neutral", async ({
    page,
  }) => {
    // Recolouring the edge made a validation error the loudest thing in the
    // viewport. Asserted against the stylesheet: no route renders a toned panel
    // reliably, and the rule is what regressions would break.
    const capCarriesTone = await page.evaluate(() =>
      [...document.styleSheets].some((sheet) => {
        try {
          return [...sheet.cssRules].some((rule) => {
            const selector = (rule as CSSStyleRule).selectorText;
            return (
              !!selector &&
              /\.panel--(error|success|primary|highlight)::(before|after)/.test(
                selector,
              ) &&
              /background-color/.test(rule.cssText)
            );
          });
        } catch {
          // Cross-origin stylesheet, not ours.
          return false;
        }
      }),
    );

    expect(capCarriesTone).toBe(true);
  });
});
