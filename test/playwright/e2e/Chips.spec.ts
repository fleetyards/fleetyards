import type { Page } from "@playwright/test";
import { app, appScenario } from "../support/on-rails";
import { test, expect } from "../support/commands";

/*
 * Guards the invariants of the rebuilt filter chips.
 *
 * Asserted against the public hangar's group row rather than the visual-tests
 * page: those routes are gated out of any production build, which the e2e run
 * uses. Public rather than the signed-in hangar because it renders the same
 * GroupLabels with the same tri-state filter and needs no session.
 *
 * The tri-state cycle is the behaviour a screenshot cannot confirm - neutral,
 * then included, then excluded, then back - and the stylesheet this replaces
 * expressed the third state with colour alone and gave no keyboard route to it.
 *
 * Needs the `chips` scenario: a public hangar with two groups holding vehicles.
 */

const chip = (page: Page, name: string) =>
  page.getByTestId("chip").filter({ hasText: name }).first();

const toggle = (page: Page, name: string) =>
  chip(page, name).locator("button").first();

test.describe("Chips", () => {
  test.beforeEach(async ({ page }) => {
    await app("clean");
    await appScenario("chips");

    await page.goto("/hangar/chips/");

    await expect(chip(page, "Combat")).toBeVisible();
  });

  test("cycles neutral, included, excluded and back", async ({ page }) => {
    const combat = toggle(page, "Combat");

    await expect(combat).toHaveAttribute("aria-pressed", "false");

    await combat.click();
    await expect(combat).toHaveAttribute("aria-pressed", "true");
    await expect(page).toHaveURL(/hangarGroupsIn/);

    await combat.click();
    await expect(combat).toHaveAttribute("aria-pressed", "false");
    await expect(page).toHaveURL(/hangarGroupsNotIn/);

    await combat.click();
    await expect(combat).toHaveAttribute("aria-pressed", "false");
    await expect(page).not.toHaveURL(/hangarGroups(In|NotIn)=/);
  });

  test("the excluded state is not signalled by colour alone", async ({
    page,
  }) => {
    // WCAG 1.4.1. The stylesheet this replaces painted the chip `darkred` and
    // said nothing else, so "excluded" was indistinguishable from "styled red".
    const combat = toggle(page, "Combat");

    await combat.click();
    await combat.click();

    await expect(combat.locator("i")).toBeVisible();
    await expect(combat).toContainText("excluded");
  });

  test("a chip is reachable and operable from the keyboard", async ({
    page,
  }) => {
    // The row was built from <a> elements with click handlers, no href and no
    // tabindex, so none of these filters could be reached without a mouse.
    const combat = toggle(page, "Combat");

    await combat.focus();
    await expect(combat).toBeFocused();

    await page.keyboard.press("Enter");

    await expect(combat).toHaveAttribute("aria-pressed", "true");
  });

  test("the row renders the label it is passed", async ({ page }) => {
    // Every call site passed `label`; GroupLabels never declared it and rendered
    // a hardcoded string instead, and ClassLabels declared it and ignored it.
    await expect(page.getByTestId("chip-row").first()).toContainText("Groups");
  });

  test("chips carry no margin of their own", async ({ page }) => {
    // Spacing belongs to the row, as it does for Btn.
    const combat = chip(page, "Combat");

    for (const side of ["top", "right", "bottom", "left"]) {
      expect(
        await combat.evaluate(
          (el, prop) => getComputedStyle(el).getPropertyValue(prop),
          `margin-${side}`,
        ),
      ).toBe("0px");
    }
  });

  test("a chip carries no end-caps", async ({ page }) => {
    // Deliberate: at chip width a cap inset 12% per side is a third of the
    // element, and a wrapping row of them is a denser repetition than the card
    // grid `.panel--slim` already drops its caps for.
    const caps = await chip(page, "Combat").evaluate((el) =>
      ["::before", "::after"].map(
        (pseudo) => getComputedStyle(el, pseudo).content,
      ),
    );

    for (const content of caps) {
      expect(content).toBe("none");
    }
  });

  test("every chip in the row shares one surface", async ({ page }) => {
    // Two components render chips - groups here, classifications on the
    // signed-in hangar beside them - and they were styled by one global
    // stylesheet each half-owned. They are one primitive now.
    const surface = (name: string) =>
      chip(page, name).evaluate((el) => {
        const cs = getComputedStyle(el);
        return {
          background: cs.backgroundColor,
          border: cs.borderColor,
          radius: cs.borderRadius,
        };
      });

    expect(await surface("Cargo")).toEqual(await surface("Combat"));
  });
});
