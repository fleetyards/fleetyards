import { test, expect } from "../support/commands";

/*
 * The media components differ in what they do when the image is not there, and
 * the differences are deliberate: a bundled placeholder, an icon, or nothing at
 * all. Asserted against visual-tests/media.vue, which stands all four next to
 * each other with no data behind them.
 *
 * Run as CI does - CI=1, against precompiled assets.
 */

test.describe("Media", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/visual-tests/media/");
    await expect(page.locator(".visual-tests")).toBeVisible();
  });

  test("LazyImage lands on the placeholder from both directions", async ({
    page,
  }) => {
    // A missing src and one that resolves to nothing both end at the same
    // bundled placeholder - the first never loads, the second falls back after
    // failing - so only the class tells them apart.
    // Chicken and egg: the error image only exists once a load has failed, and
    // a load is only attempted once the frame is on screen. So the frame gets
    // scrolled to, not the image inside it.
    const column = page.locator(".col-lg-4", { hasText: "broken src" }).first();
    await column.scrollIntoViewIfNeeded();

    const broken = column.locator(".lazy-image__img--error");

    await expect(broken).toHaveAttribute("src", /store_image/);
  });

  test("Avatar falls back to the icon when the image fails", async ({
    page,
  }) => {
    // Not to the img's alt text, which the round frame clips - a deleted upload
    // or a CDN miss used to show up as a cropped word.
    const broken = page
      .locator(".avatar", { has: page.locator("img[src*='does-not-exist']") })
      .first();

    await expect(broken).toHaveCount(0);
    // Every avatar on the page either shows an image that loads, or the icon.
    const stranded = await page.evaluate(
      () =>
        [...document.querySelectorAll<HTMLImageElement>(".avatar img")].filter(
          (img) => img.complete && img.naturalWidth === 0,
        ).length,
    );

    expect(stranded).toBe(0);
  });

  test("ViewImage renders nothing when told to skip its fallback", async ({
    page,
  }) => {
    // What a card wants when it must not show a frame it cannot fill.
    const column = page
      .locator(".col-lg-4", { hasText: "withoutFallback" })
      .first();

    await expect(column).toBeVisible();
    await expect(column.locator("img")).toHaveCount(0);
  });

  test("no YouTube iframe exists before consent", async ({ page }) => {
    // The whole point of the placeholder: nothing may reach YouTube until the
    // visitor has agreed, so the iframe must be absent rather than hidden.
    await expect(page.locator("iframe")).toHaveCount(0);
    await expect(page.locator(".youtube-placeholder")).toBeVisible();

    await page.getByTestId("toggle-youtube-consent").click();

    await expect(page.locator("iframe")).toHaveCount(1);
    await expect(page.locator(".youtube-placeholder")).toHaveCount(0);
  });

  test("the consent prompt's own buttons keep a gap", async ({ page }) => {
    // They had none: the container carried no rules at all and Btn ships no
    // margin, so the two read as one control. This is app CSS, not the demo's.
    const gap = await page.evaluate(() => {
      const buttons = [
        ...document.querySelectorAll<HTMLElement>(
          ".youtube-placeholder-buttons .btn",
        ),
      ];
      if (buttons.length < 2) return -1;
      return (
        buttons[1].getBoundingClientRect().left -
        buttons[0].getBoundingClientRect().right
      );
    });

    expect(gap).toBeGreaterThan(0);
  });
});
