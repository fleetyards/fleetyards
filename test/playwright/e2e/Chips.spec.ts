import type { Page } from "@playwright/test";
import { app, appScenario } from "../support/on-rails";
import { test, expect } from "../support/commands";

/*
 * Guards the invariants of the rebuilt filter chips.
 *
 * Asserted against the public hangar's group row rather than visual-tests/chips.vue.
 * The gallery page is reachable from the e2e build now, but it renders ChipRow over
 * a static array with no filters store and no router behind it, and every
 * assertion here is about state that round-trips through the query string. Public
 * rather than the signed-in hangar because it renders the same GroupLabels with
 * the same tri-state filter and needs no session.
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
    // Load-bearing wait, not politeness: the state round-trips through the query
    // string and useFilters debounces that write, so a second click landing
    // before the first has applied reads the same pre-update filters and sets
    // `included` again rather than advancing to `excluded`.
    await expect(combat).toHaveAttribute("aria-pressed", "true");

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

test.describe("Chips - read-only row", () => {
  test("draws no grip and does not reorder", async ({ page }) => {
    // The public hangar is someone else's order. Sortable used to be bound here
    // regardless, so a visitor could drag the row and fire the owner-only sort.
    await app("clean");
    await appScenario("chips");
    await page.goto("/hangar/chips/");
    await expect(chip(page, "Combat")).toBeVisible();

    await expect(page.getByTestId("chip-handle")).toHaveCount(0);
    await expect(page.getByTestId("chip-edit")).toHaveCount(0);
  });
});

/*
 * The edit mode, against visual-tests/chips/ - the gallery mirrors GroupLabels'
 * toggle and Sortable options, and needs no session.
 */
test.describe("Chips - edit mode", () => {
  const editableRow = (page: Page) =>
    page.getByTestId("chip-row").filter({ hasText: "Groups" }).first();

  const names = (page: Page) =>
    editableRow(page)
      .getByTestId("chip")
      .locator(".chip__label")
      .allInnerTexts();

  const chips = (page: Page) => editableRow(page).getByTestId("chip");

  test.beforeEach(async ({ page }) => {
    await page.goto("/visual-tests/chips/");
    await expect(chips(page).first()).toBeVisible();
  });

  test("a row at rest reserves no space for controls", async ({ page }) => {
    // Hiding them with opacity left an empty slot on every chip.
    await expect(editableRow(page).getByTestId("chip-handle")).toHaveCount(0);
    await expect(editableRow(page).getByTestId("chip-edit")).toHaveCount(0);
  });

  test("edit mode adds a grip and an edit action to every chip", async ({
    page,
  }) => {
    const count = await chips(page).count();

    await editableRow(page).getByTestId("group-labels-edit").click();

    await expect(editableRow(page).getByTestId("chip-handle")).toHaveCount(
      count,
    );
    await expect(editableRow(page).getByTestId("chip-edit")).toHaveCount(count);
  });

  test("reorders only in edit mode, and only by the grip", async ({ page }) => {
    const before = await names(page);

    await chips(page)
      .nth(0)
      .locator(".chip__toggle")
      .dragTo(chips(page).nth(2));
    expect(await names(page)).toEqual(before);

    await editableRow(page).getByTestId("group-labels-edit").click();

    // A toggle that also dragged could not be clicked without moving it.
    await chips(page)
      .nth(0)
      .locator(".chip__toggle")
      .dragTo(chips(page).nth(2));
    expect(await names(page)).toEqual(before);

    await chips(page)
      .nth(0)
      .getByTestId("chip-handle")
      .dragTo(chips(page).nth(2));
    await expect.poll(() => names(page)).not.toEqual(before);
  });
});

/*
 * The real GroupLabels on the owner's hangar: the hover reveal, and a reorder
 * that reaches the server by drag and by keyboard. Reuses the chips scenario's
 * user, whose Combat and Cargo groups are created in that order.
 */
test.describe("Chips - owner's hangar", () => {
  const groupRow = (page: Page) =>
    page.getByTestId("chip-row").filter({ hasText: "Combat" }).first();

  const names = (page: Page) =>
    groupRow(page).getByTestId("chip").locator(".chip__label").allInnerTexts();

  const sorted = (page: Page) =>
    page.waitForResponse(
      (response) =>
        response.url().includes("/hangar/groups/sort") &&
        response.request().method() === "PUT",
    );

  test.beforeEach(async ({ page }) => {
    await app("clean");
    await appScenario("chips");

    await page.goto("/login/");
    await page.locator("input[name='login']").fill("chips");
    await page.locator("input[name='password']").fill("password");

    const sessionCreated = page.waitForResponse(
      (response) =>
        response.url().includes("/api/v1/sessions") &&
        response.request().method() === "POST",
    );
    await page.getByTestId("submit-login").click();
    await sessionCreated;
    await expect(page).not.toHaveURL(/\/login/);

    await page.goto("/hangar/");
    await expect(groupRow(page)).toBeVisible();
  });

  test("the edit button shows with the row, not after a click", async ({
    page,
  }) => {
    const edit = groupRow(page).getByTestId("group-labels-edit");
    const opacity = () => edit.evaluate((el) => getComputedStyle(el).opacity);

    await page.mouse.move(0, 0);
    await expect.poll(opacity).toBe("0");

    await groupRow(page).hover();
    await expect.poll(opacity).toBe("1");

    // A clicked chip keeps focus; that must not hold the button on screen.
    await groupRow(page)
      .getByTestId("chip")
      .first()
      .locator(".chip__toggle")
      .click();
    await page.mouse.move(0, 0);
    await expect.poll(opacity).toBe("0");
  });

  // The scenario's two groups tie on `sort`, so their starting order is not
  // fixed; each test moves whichever chip is second to the front.
  test("a drag by the grip persists", async ({ page }) => {
    const before = await names(page);
    const reversed = [...before].reverse();

    await groupRow(page).hover();
    await groupRow(page).getByTestId("group-labels-edit").click();

    const chips = groupRow(page).getByTestId("chip");
    const request = sorted(page);
    await chips
      .nth(1)
      .getByTestId("chip-handle")
      .dragTo(chips.nth(0), { targetPosition: { x: 4, y: 4 } });
    await request;

    await page.reload();
    await expect.poll(() => names(page)).toEqual(reversed);
  });

  test("the grip moves a chip from the keyboard", async ({ page }) => {
    const before = await names(page);
    const reversed = [...before].reverse();

    await groupRow(page).hover();
    await groupRow(page).getByTestId("group-labels-edit").click();

    const handle = groupRow(page)
      .getByTestId("chip")
      .filter({ hasText: before[1] })
      .getByTestId("chip-handle");

    await handle.focus();

    const request = sorted(page);
    await page.keyboard.press("ArrowLeft");
    await request;

    expect(await names(page)).toEqual(reversed);
    await expect(handle).toBeFocused();

    await page.reload();
    await expect.poll(() => names(page)).toEqual(reversed);
  });

  test("quick moves save one at a time and keep the last order", async ({
    page,
  }) => {
    // Each request writes a full order; overlapping ones could finish out of
    // order and persist an earlier one.
    // Counted in the route handler, which releases each response only after
    // decrementing, so the page cannot start the next request early. The delay
    // keeps the first request open while every key is pressed.
    let inFlight = 0;
    let maxInFlight = 0;
    let sent = 0;

    await page.route(/\/hangar\/groups\/sort/, async (route) => {
      sent += 1;
      inFlight += 1;
      maxInFlight = Math.max(maxInFlight, inFlight);

      await new Promise((resolve) => setTimeout(resolve, 500));
      const response = await route.fetch();

      inFlight -= 1;
      await route.fulfill({ response });
    });

    const before = await names(page);

    await groupRow(page).hover();
    await groupRow(page).getByTestId("group-labels-edit").click();

    const handle = groupRow(page)
      .getByTestId("chip")
      .filter({ hasText: before[1] })
      .getByTestId("chip-handle");

    await handle.focus();
    await page.keyboard.press("ArrowLeft");
    await page.keyboard.press("ArrowRight");
    await page.keyboard.press("ArrowLeft");
    await page.keyboard.press("ArrowRight");

    // The first press, then one request carrying the order after the last.
    await expect.poll(() => sent === 2 && inFlight === 0).toBe(true);
    expect(maxInFlight).toBe(1);
    expect(await names(page)).toEqual(before);

    await page.reload();
    await expect.poll(() => names(page)).toEqual(before);
  });

  test("a failure after a success shows what the server saved", async ({
    page,
  }) => {
    // The first request is held and succeeds, the one queued behind it fails.
    // The page's own group list still predates both - no refetch arrives in
    // the test environment - so falling back to it would show neither.
    let calls = 0;
    await page.route(/\/hangar\/groups\/sort/, async (route) => {
      calls += 1;

      if (calls === 1) {
        await new Promise((resolve) => setTimeout(resolve, 500));
        await route.continue();
        return;
      }

      await route.fulfill({
        status: 500,
        contentType: "application/json",
        body: JSON.stringify({ code: "error", message: "Sort failed" }),
      });
    });

    const before = await names(page);
    const reversed = [...before].reverse();

    await groupRow(page).hover();
    await groupRow(page).getByTestId("group-labels-edit").click();

    await groupRow(page)
      .getByTestId("chip")
      .filter({ hasText: before[1] })
      .getByTestId("chip-handle")
      .focus();

    await page.keyboard.press("ArrowLeft");
    await page.keyboard.press("ArrowRight");

    await expect.poll(() => calls).toBe(2);
    await expect.poll(() => names(page)).toEqual(reversed);
  });

  test("a failed save puts the saved order back", async ({ page }) => {
    await page.route(/\/hangar\/groups\/sort/, (route) =>
      route.fulfill({
        status: 500,
        contentType: "application/json",
        body: JSON.stringify({ code: "error", message: "Sort failed" }),
      }),
    );

    const before = await names(page);

    await groupRow(page).hover();
    await groupRow(page).getByTestId("group-labels-edit").click();

    await groupRow(page)
      .getByTestId("chip")
      .filter({ hasText: before[1] })
      .getByTestId("chip-handle")
      .focus();

    const request = sorted(page);
    await page.keyboard.press("ArrowLeft");
    await request;

    await expect.poll(() => names(page)).toEqual(before);
  });
});

/*
 * Below the mobile breakpoint the row is a dropdown. Its edit mode reorders
 * with arrows instead of a drag, and has to stay open while they are used.
 */
test.describe("Chips - owner's hangar on mobile", () => {
  const menu = (page: Page) =>
    page.getByTestId("dropdown-list").filter({
      has: page.getByTestId("group-menu-edit-toggle"),
    });

  const menuNames = (page: Page) =>
    menu(page)
      .getByTestId("group-menu-row")
      .locator(".chip__label")
      .allInnerTexts();

  test.beforeEach(async ({ page }) => {
    await page.setViewportSize({ width: 430, height: 900 });

    await app("clean");
    await appScenario("chips");

    await page.goto("/login/");
    await page.locator("input[name='login']").fill("chips");
    await page.locator("input[name='password']").fill("password");

    const sessionCreated = page.waitForResponse(
      (response) =>
        response.url().includes("/api/v1/sessions") &&
        response.request().method() === "POST",
    );
    await page.getByTestId("submit-login").click();
    await sessionCreated;
    await expect(page).not.toHaveURL(/\/login/);

    await page.goto("/hangar/");
    await page
      .getByTestId("chip-row")
      .filter({ hasText: "Groups" })
      .locator("button")
      .first()
      .click();
    await expect(menu(page)).toBeVisible();
  });

  test("edit mode swaps the filters for move and edit controls", async ({
    page,
  }) => {
    await expect(menu(page).getByTestId("group-menu-row")).toHaveCount(0);

    await menu(page).getByTestId("group-menu-edit-toggle").click();

    // Still open: the toggle must not close the menu it changes.
    await expect(menu(page)).toBeVisible();
    await expect(menu(page).getByTestId("group-menu-row")).toHaveCount(2);

    const first = menu(page).getByTestId("group-menu-row").first();
    await expect(first.getByTestId("group-menu-move-up")).toBeDisabled();
    await expect(first.getByTestId("group-menu-move-down")).toBeEnabled();
  });

  test("an arrow moves a group and the order persists", async ({ page }) => {
    await menu(page).getByTestId("group-menu-edit-toggle").click();

    const before = await menuNames(page);
    const reversed = [...before].reverse();

    const sortedRequest = page.waitForResponse(
      (response) =>
        response.url().includes("/hangar/groups/sort") &&
        response.request().method() === "PUT",
    );
    await menu(page)
      .getByTestId("group-menu-row")
      .first()
      .getByTestId("group-menu-move-down")
      .click();
    await sortedRequest;

    await expect(menu(page)).toBeVisible();
    expect(await menuNames(page)).toEqual(reversed);

    // Moved to the bottom, so its down arrow is disabled and the up arrow of
    // the same row takes focus.
    await expect(
      menu(page)
        .getByTestId("group-menu-row")
        .last()
        .getByTestId("group-menu-move-up"),
    ).toBeFocused();

    await page.reload();
    await page
      .getByTestId("chip-row")
      .filter({ hasText: "Groups" })
      .locator("button")
      .first()
      .click();
    await menu(page).getByTestId("group-menu-edit-toggle").click();
    await expect.poll(() => menuNames(page)).toEqual(reversed);
  });

  // Every control in the menu, not only the edit rows: Add Group sits outside
  // them, and the menu is teleported out of reach of the row's listener.
  for (const control of ["group-menu-move-down", "group-menu-add"]) {
    test(`Escape from ${control} leaves edit mode`, async ({ page }) => {
      await menu(page).getByTestId("group-menu-edit-toggle").click();

      await menu(page).getByTestId(control).first().focus();
      await page.keyboard.press("Escape");

      await expect(menu(page).getByTestId("group-menu-row")).toHaveCount(0);
      await expect(
        menu(page).getByTestId("group-menu-edit-toggle"),
      ).toBeFocused();
    });
  }
});
