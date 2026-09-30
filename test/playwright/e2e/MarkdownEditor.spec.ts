import { test, expect } from "../support/commands";

/*
 * The size of a selected image is chosen from a toolbar floating over it,
 * outside the editable text. A keyboard user reaches it with Tab -- which takes
 * focus out of the text -- so it has to stay open while focus is inside it,
 * and give focus back to the text on the way out.
 *
 * Driven on visual-tests/forms, where the editor sits next to what the page
 * renders from its markdown.
 */
test.describe("Markdown editor image size", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/visual-tests/forms/");

    const toggle = page.getByTestId("markdown-editor-source").first();
    await toggle.click();
    await page
      .getByTestId("source-markdown")
      .fill("Before\n\n![banner](/banner.jpg)\n\nAfter");
    await toggle.click();

    await page.getByTestId("input-markdown").locator("img").click();
  });

  test("is chosen with the keyboard from the toolbar over the image", async ({
    page,
  }) => {
    const toolbar = page.getByTestId("markdown-editor-image-size");
    await expect(toolbar).toBeVisible();

    await page.keyboard.press("Tab");
    await expect(
      page.getByTestId("markdown-editor-image-size-25"),
    ).toBeFocused();

    await page.keyboard.press("Tab");
    await expect(
      page.getByTestId("markdown-editor-image-size-50"),
    ).toBeFocused();
    await expect(toolbar).toBeVisible();

    await page.keyboard.press("Enter");

    await expect(
      page.getByTestId("markdown-preview").locator("img"),
    ).toHaveAttribute("data-size", "50");
    await expect(toolbar).toBeVisible();
  });

  test("hands focus back to the text when tabbing out backwards", async ({
    page,
  }) => {
    await page.keyboard.press("Tab");
    await expect(
      page.getByTestId("markdown-editor-image-size-25"),
    ).toBeFocused();

    await page.keyboard.press("Shift+Tab");

    await expect(page.getByTestId("input-markdown")).toBeFocused();
  });
});
