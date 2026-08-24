import { test, expect } from "../support/commands";

/*
 * The gallery was written for desktop width and never checked below it, which
 * left a whole class of bug invisible: at 390px the forms page scrolled
 * sideways over a slider label and the events page over a button group.
 *
 * Asserted on the document rather than on elements. Two things make the
 * element-level version unreliable here: the collapsed mobile navigation sits
 * off-screen on purpose, and a table wider than the viewport is correct as long
 * as it scrolls inside its own container - which is exactly what the document
 * check distinguishes.
 *
 * Widths chosen against this project's own breakpoints, which are far larger
 * than Bootstrap's: md starts at 992px and lg at 1500px, so 390 / 768 / 1280 are
 * three genuinely different layouts and 1440 - what the suite used to use - only
 * ever exercised the middle one.
 */

const routes = [
  "typography",
  "panels",
  "buttons",
  "chips",
  "media",
  "tables",
  "lists",
  "metrics",
  "charts",
  "states",
  "notifications",
  "support-hint",
  "sync-modal",
  "overlays",
  "forms",
  "events",
];

for (const width of [390, 768, 1280]) {
  test(`no page scrolls sideways at ${width}px`, async ({ page }) => {
    await page.setViewportSize({ width, height: 900 });

    const scrolling: string[] = [];

    for (const route of routes) {
      await page.goto(`/visual-tests/${route}/`);
      await expect(page.locator(".visual-tests")).toBeVisible();

      const doc = await page.evaluate(() => ({
        scroll: document.documentElement.scrollWidth,
        client: document.documentElement.clientWidth,
      }));

      if (doc.scroll > doc.client + 1) {
        scrolling.push(`${route} (${doc.scroll} > ${doc.client})`);
      }
    }

    expect(scrolling, `pages scrolling sideways at ${width}px`).toEqual([]);
  });
}
