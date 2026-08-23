import { test, expect } from "../support/commands";

/*
 * Btn ships no margin of its own - spacing belongs to the container - so any
 * demo page that puts buttons side by side has to bring a row that gaps them.
 * Twice now a page was missed: once because it had no spacing container at all,
 * once because the buttons came from a `v-for` and so were invisible to a search
 * for adjacent siblings in the markup.
 *
 * Measured on screen rather than read off the templates, which is what makes it
 * catch the `v-for` case. Every gallery route is listed, so a new page is not
 * quietly left out.
 *
 * Both axes, because the third miss was vertical: three paginators stacked in
 * bare rows with nothing between them. A paginator is a BtnGroup, so the
 * horizontal pass skipped it twice over - members of a group are meant to touch,
 * but two whole groups are not.
 */

const routes = [
  "panels",
  "events",
  "buttons",
  "tables",
  "typography",
  "forms",
  "lists",
  "metrics",
  "states",
  "notifications",
  "sync-modal",
  "support-hint",
  "chips",
  "media",
  "charts",
];

for (const route of routes) {
  test(`buttons keep a gap on /visual-tests/${route}/`, async ({ page }) => {
    await page.goto(`/visual-tests/${route}/`);
    await expect(page.locator(".visual-tests")).toBeVisible();

    const touching = await page.evaluate(() => {
      const bad: string[] = [];
      const MIN_GAP = 4;

      // A whole BtnGroup counts as one control: its own members are meant to
      // touch, but it must not touch the control next to or below it.
      const controls = [
        ...document.querySelectorAll<HTMLElement>(".btn, .btn-group"),
      ].filter(
        (el) =>
          el.offsetParent !== null &&
          !el.parentElement?.closest(".btn-group") &&
          !(el.classList.contains("btn") && el.closest(".btn-group")),
      );

      const name = (el: HTMLElement) =>
        `"${el.textContent?.replace(/\s+/g, " ").trim().slice(0, 24)}"`;

      for (const first of controls) {
        for (const second of controls) {
          if (first === second) continue;
          const a = first.getBoundingClientRect();
          const b = second.getBoundingClientRect();
          if (!a.width || !b.width) continue;

          // Side by side: same vertical band, `second` to the right.
          if (Math.abs(a.top - b.top) < MIN_GAP && b.left >= a.left) {
            const gap = b.left - a.right;
            if (gap >= 0 && gap < MIN_GAP) {
              bad.push(
                `${name(first)} / ${name(second)} side by side, gap=${gap.toFixed(1)}px`,
              );
            }
          }

          // Stacked: horizontal ranges overlap, `second` below.
          const overlap = Math.min(a.right, b.right) - Math.max(a.left, b.left);
          if (overlap > Math.min(a.width, b.width) / 2 && b.top >= a.top) {
            const gap = b.top - a.bottom;
            if (gap >= 0 && gap < MIN_GAP) {
              bad.push(
                `${name(first)} / ${name(second)} stacked, gap=${gap.toFixed(1)}px`,
              );
            }
          }
        }
      }
      return bad;
    });

    expect(touching, "controls with no gap between them").toEqual([]);
  });
}
