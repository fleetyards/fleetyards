import { test, expect } from "../support/commands";

/*
 * AppConfirm and OffCanvas are singletons mounted in App.vue and driven by
 * comlink events, so they are only ever on screen mid-action - the confirm
 * during a destructive click, and the off-canvas on mobile, where FilteredList
 * is the only thing that opens it. The demo page asks for both directly, which
 * is what makes them testable at desktop width at all.
 */

test.describe("Overlays", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/visual-tests/overlays/");
    await expect(page.locator(".visual-tests")).toBeVisible();
  });

  test("the confirm runs its handler and closes", async ({ page }) => {
    await page.getByTestId("confirm-default").click();

    const confirm = page.locator(".app-confirm, [class*='confirm']").first();
    await expect(confirm).toBeVisible();

    await page.getByText("Confirm", { exact: true }).click();

    await expect(page.getByText("confirmed (default text)")).toBeVisible();
  });

  test("escape cancels the confirm", async ({ page }) => {
    // Keyboard is the half no screenshot covers: Enter confirms, Escape cancels.
    await page.getByTestId("confirm-custom").click();
    await expect(page.getByText("Delete it")).toBeVisible();

    await page.keyboard.press("Escape");

    await expect(page.getByText("cancelled (custom text)")).toBeVisible();
    await expect(page.getByText("Delete it")).toHaveCount(0);
  });

  test("enter confirms the confirm", async ({ page }) => {
    await page.getByTestId("confirm-default").click();
    await expect(page.getByText("Confirm", { exact: true })).toBeVisible();

    await page.keyboard.press("Enter");

    await expect(page.getByText("confirmed (default text)")).toBeVisible();
  });

  test("the off-canvas opens on either side and closes", async ({ page }) => {
    const panel = page.locator(".off-canvas__panel");
    const content = page.getByTestId("off-canvas-demo-content");

    // Teleported once and left there, so it exists before the panel opens.
    await expect(content).toHaveCount(1);

    await page.getByTestId("off-canvas-left").click();
    await expect(panel).toBeVisible();
    await expect(page.getByText("Filters")).toBeVisible();

    // Closed from inside, because the backdrop covers everything on the page
    // while the panel is open - which is the point of it.
    await page.getByTestId("off-canvas-inner-close").click();
    await expect(page.locator(".off-canvas__backdrop")).toHaveCount(0);

    await page.getByTestId("off-canvas-right").click();
    await expect(panel).toBeVisible();
    await expect(page.getByText("Details")).toBeVisible();
  });

  /*
   * Both entrances were reported as "sometimes sliding in from the middle". Two
   * separate causes: a `setTimeout(50)` that did not guarantee the start state
   * was painted, and - for the off-canvas - the side class flip itself being
   * animated, so the panel travelled between the two off-screen positions and
   * crossed the viewport on the way.
   *
   * Sampled immediately after the click, which is the only moment the start
   * state exists.
   */
  test("the off-canvas starts at the edge it opens from", async ({ page }) => {
    const startTransform = async (hook: string) => {
      await page.getByTestId(hook).click();
      const transform = await page.evaluate(() => {
        const panel = document.querySelector<HTMLElement>(".off-canvas__panel");
        return getComputedStyle(panel!).transform;
      });
      await page.waitForTimeout(700);
      return transform;
    };

    // Twice round, because the wrong start only showed after a side change.
    for (const round of [1, 2]) {
      expect(
        await startTransform("off-canvas-left"),
        `left start, round ${round}`,
      ).toBe("matrix(1, 0, 0, 1, -300, 0)");
      await page.getByTestId("off-canvas-inner-close").click();
      await page.waitForTimeout(700);

      expect(
        await startTransform("off-canvas-right"),
        `right start, round ${round}`,
      ).toBe("matrix(1, 0, 0, 1, 300, 0)");
      await page.getByTestId("off-canvas-inner-close").click();
      await page.waitForTimeout(700);
    }
  });

  test("the confirm arrives from above over a scrim", async ({ page }) => {
    await page.getByTestId("confirm-default").click();

    const start = await page.evaluate(() => {
      const overlay = document.querySelector<HTMLElement>(".app-confirm");
      const dialog = document.querySelector<HTMLElement>(
        ".app-confirm__dialog",
      );
      return {
        scrim: getComputedStyle(overlay!).backgroundColor,
        opacity: getComputedStyle(overlay!).opacity,
        transform: getComputedStyle(dialog!).transform,
      };
    });

    // It used to have no scrim at all, and animated the full-screen container.
    expect(start.scrim).not.toBe("rgba(0, 0, 0, 0)");
    expect(start.opacity).toBe("0");
    expect(start.transform).not.toBe("matrix(1, 0, 0, 1, 0, 0)");

    await expect
      .poll(() =>
        page.evaluate(
          () =>
            getComputedStyle(
              document.querySelector<HTMLElement>(".app-confirm")!,
            ).opacity,
        ),
      )
      .toBe("1");
  });

  test("a crumb without a target is not a link", async ({ page }) => {
    const crumbs = page.locator(".bread-crumbs, [class*='crumb']").first();
    await expect(crumbs).toBeVisible();

    // The last crumb is the current page, so it must not be clickable.
    const last = crumbs.locator("li").last();
    await expect(last.locator("a")).toHaveCount(0);
  });
});
