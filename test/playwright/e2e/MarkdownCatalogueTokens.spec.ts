import { test, expect } from "../support/commands";
import { app, appFactories } from "../support/on-rails";

/*
 * An item named inline -- typed as `[*` and part of its name, picked from the
 * suggestions -- is kept as a token in the text and shown as a link to the
 * item, with its stats card, wherever the text is read.
 *
 * Driven on visual-tests/forms, where the editor sits next to what the page
 * renders from its markdown.
 */
test.describe("Markdown catalogue tokens", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean");
    await appFactories([["create", "commodity", { name: "Quantainium" }]]);

    await page.goto("/visual-tests/forms/");

    const toggle = page.getByTestId("markdown-editor-source").first();
    await toggle.click();
    await page.getByTestId("source-markdown").fill("");
    await toggle.click();
  });

  test("is picked from the suggestions and rendered as a link", async ({
    page,
  }) => {
    const text = page.getByTestId("input-markdown");
    await text.click();
    await page.keyboard.type("Mine [*quant");

    const suggestion = page.getByTestId(
      "markdown-editor-item-suggestion-quantainium",
    );
    await expect(suggestion).toBeVisible();

    await page.keyboard.press("Enter");

    await expect(text.locator("[data-catalogue-token]")).toHaveText(
      "Quantainium",
    );

    const link = page
      .getByTestId("markdown-preview")
      .locator(".catalogue-token a");
    await expect(link).toHaveText("Quantainium");
    await expect(link).toHaveAttribute("href", /quantainium/);
  });
});
