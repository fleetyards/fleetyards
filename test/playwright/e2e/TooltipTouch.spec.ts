import { test, expect, devices } from "@playwright/test";

/*
 * A phone has nothing to hover with, so a tap is the only way to open a
 * tooltip. It used to do the opposite: `click` was wired straight to hide, so
 * the tooltip a tap had just opened through the synthetic mouse events closed
 * again in the same gesture, and the text was unreachable on touch.
 *
 * The unit spec covers the branch with a stubbed `matchMedia`. This one runs it
 * on a real touch-emulating context, which is where the event ordering that
 * caused the bug actually happens.
 *
 * Chromium rather than the iPhone profile: the repo installs no WebKit.
 */
test.use({ ...devices["Pixel 5"] });

const tooltipState = (page: import("@playwright/test").Page) =>
  page.evaluate(() => {
    const el = document.querySelector("[data-tooltip]") as HTMLElement | null;
    if (!el) return "absent";
    return `${el.style.display}/${el.style.opacity}`;
  });

test.describe("Tooltip on touch", () => {
  test("a tap opens it and the next one closes it", async ({ page }) => {
    await page.goto("/visual-tests/forms/");
    await expect(page.locator(".visual-tests")).toBeVisible();

    const icon = page.locator("[data-test='info-hints'] .hint-icon").first();
    await icon.scrollIntoViewIfNeeded();

    await icon.tap();
    await expect
      .poll(() => tooltipState(page), { timeout: 2000 })
      .toBe("block/1");

    // Still up after the fade would have finished -- the bug hid it ~150ms in.
    await page.waitForTimeout(600);
    expect(await tooltipState(page)).toBe("block/1");

    await icon.tap();
    await expect.poll(() => tooltipState(page)).toBe("none/0");
  });

  test("tapping elsewhere dismisses it", async ({ page }) => {
    await page.goto("/visual-tests/forms/");
    await expect(page.locator(".visual-tests")).toBeVisible();

    const icon = page.locator("[data-test='info-hints'] .hint-icon").first();
    await icon.scrollIntoViewIfNeeded();
    await icon.tap();
    await expect
      .poll(() => tooltipState(page), { timeout: 2000 })
      .toBe("block/1");

    await page.locator("[data-test='info-hints']").tap({ position: { x: 5, y: 5 } });

    await expect.poll(() => tooltipState(page)).toBe("none/0");
  });
});
