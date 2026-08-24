import { test, expect } from "../support/commands";

/*
 * The inline confirm: a trigger that becomes a question in place, for decisions
 * the modal AppConfirm is too heavy for. Composed from Btn and BtnGroup, so what
 * is worth testing is not how it looks but when it arms and - more importantly -
 * when it lets go, since an armed "yes" left sitting in a list is a trap.
 *
 * Run as CI does: CI=1, against precompiled assets.
 */

const row = (page: import("@playwright/test").Page, ship: string) =>
  page.getByTestId(`ship-row-${ship}`);

test.describe("BtnConfirm", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/visual-tests/buttons/");
    await expect(row(page, "Aegis Idris P")).toBeVisible();
  });

  test("asks in place and only acts on yes", async ({ page }) => {
    const idris = row(page, "Aegis Idris P");

    await idris.getByTestId("btn-confirm-trigger").click();

    // The trigger is gone, replaced by the question and two answers.
    await expect(idris.getByTestId("btn-confirm-trigger")).toHaveCount(0);
    await expect(idris.getByTestId("btn-confirm-question")).toHaveText(
      "Remove?",
    );

    await idris.getByTestId("btn-confirm-yes").click();

    await expect(row(page, "Aegis Idris P")).toHaveCount(0);
    await expect(page.getByTestId("removed-log")).toContainText(
      "Aegis Idris P",
    );
  });

  test("no answers the question without acting", async ({ page }) => {
    const carrack = row(page, "Anvil Carrack");

    await carrack.getByTestId("btn-confirm-trigger").click();
    await carrack.getByTestId("btn-confirm-no").click();

    await expect(carrack.getByTestId("btn-confirm-trigger")).toBeVisible();
    await expect(carrack).toBeVisible();
    await expect(page.getByTestId("removed-log")).toContainText("—");
  });

  test("escape disarms", async ({ page }) => {
    const carrack = row(page, "Anvil Carrack");

    await carrack.getByTestId("btn-confirm-trigger").click();
    await expect(carrack.getByTestId("btn-confirm-yes")).toBeVisible();

    // Focus lands on the declining half, so an Enter meant for something else
    // cannot delete a row.
    await expect(carrack.getByTestId("btn-confirm-no")).toBeFocused();

    await page.keyboard.press("Escape");

    await expect(carrack.getByTestId("btn-confirm-trigger")).toBeVisible();
    await expect(carrack).toBeVisible();
  });

  test("a click elsewhere disarms", async ({ page }) => {
    const carrack = row(page, "Anvil Carrack");

    await carrack.getByTestId("btn-confirm-trigger").click();
    await expect(carrack.getByTestId("btn-confirm-yes")).toBeVisible();

    await page.locator("h1").first().click();

    await expect(carrack.getByTestId("btn-confirm-trigger")).toBeVisible();
  });

  test("arming a second question closes the first", async ({ page }) => {
    // Two open questions in one list is an invitation to answer the wrong one.
    const carrack = row(page, "Anvil Carrack");
    const cutlass = row(page, "Drake Cutlass Black");

    await carrack.getByTestId("btn-confirm-trigger").click();
    await expect(carrack.getByTestId("btn-confirm-yes")).toBeVisible();

    await cutlass.getByTestId("btn-confirm-trigger").click();

    await expect(cutlass.getByTestId("btn-confirm-yes")).toBeVisible();
    await expect(carrack.getByTestId("btn-confirm-yes")).toHaveCount(0);
    await expect(carrack.getByTestId("btn-confirm-trigger")).toBeVisible();
  });

  test("a disabled trigger cannot be armed", async ({ page }) => {
    // Addressed by hook, not by text: the label is gone once it arms.
    const disabled = page.getByTestId("confirm-disabled");

    await expect(disabled.locator(".btn")).toBeDisabled();
    await disabled.locator(".btn").click({ force: true });

    await expect(disabled.getByTestId("btn-confirm-yes")).toHaveCount(0);
  });

  test("the question can be hidden where there is no room", async ({
    page,
  }) => {
    const narrow = page.getByTestId("confirm-narrow");

    await narrow.getByTestId("btn-confirm-trigger").click();

    await expect(narrow.getByTestId("btn-confirm-question")).toHaveCount(0);
    await expect(narrow.getByTestId("btn-confirm-yes")).toBeVisible();
  });
});
