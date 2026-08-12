import type { Locator } from "@playwright/test";
import { test, expect } from "../support/commands";

/*
 * Guards the invariants of the rebuilt Btn against the visual-tests page.
 *
 * These are deliberately assertions on computed style rather than pixel
 * snapshots: every regression this file covers was an invariant violation
 * (a surface that stopped matching, a height that stopped lining up), and an
 * assertion says which invariant broke where an image diff only says "something
 * moved". Snapshot baselines would also have to be generated inside the e2e
 * container, since Playwright keys them per platform.
 */

const style = (locator: Locator, property: string) =>
  locator.evaluate(
    (el, prop) => getComputedStyle(el).getPropertyValue(prop),
    property,
  );

const box = async (locator: Locator) => {
  const b = await locator.boundingBox();
  if (!b) throw new Error("element has no bounding box");
  return b;
};

test.describe("Buttons", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/visual-tests/buttons/");
    await expect(
      page.getByRole("button", { name: "Rest", exact: true }),
    ).toBeVisible();
  });

  test("sizes match the form control heights", async ({ page }) => {
    // sm is 43px like .base-input, lg is 55px like .base-input--large, so a
    // button sits flush next to an input.
    const expected = { sm: 43, md: 48, lg: 55 };

    for (const [size, height] of Object.entries(expected)) {
      const btn = page.getByRole("button", { name: size, exact: true });
      expect(Math.round((await box(btn)).height)).toBe(height);
    }
  });

  test("an icon-only button stays square", async ({ page }) => {
    // Without a min-width it collapses to the width of the glyph.
    const btn = page
      .getByRole("button", { name: "Sync hangar", exact: true })
      .first();
    const { width, height } = await box(btn);

    expect(Math.round(width)).toBe(Math.round(height));
  });

  test("end-caps are present at the default size", async ({ page }) => {
    const btn = page.getByRole("button", { name: "Rest", exact: true });

    const caps = await btn.evaluate((el) =>
      ["::before", "::after"].map((pseudo) => {
        const cs = getComputedStyle(el, pseudo);
        return { content: cs.content, height: cs.height };
      }),
    );

    for (const cap of caps) {
      expect(cap.content).not.toBe("none");
      expect(cap.height).toBe("2px");
    }
  });

  test("disabled dims the content, not the element", async ({ page }) => {
    // Element-wide opacity turns an opaque surface translucent, which made a
    // disabled group member read as lighter than its enabled siblings.
    const btn = page.getByRole("button", { name: "Disabled", exact: true });

    expect(await style(btn, "opacity")).toBe("1");
    expect(
      Number(await style(btn.locator(".btn__content"), "opacity")),
    ).toBeLessThan(1);
  });

  test("a disabled link is a real disabled button", async ({ page }) => {
    // `disabled` has no effect on <a>, so a disabled link button used to stay
    // clickable and focusable.
    const enabled = page.getByRole("link", { name: "External href" });
    await expect(enabled).toBeVisible();

    const disabled = page.getByRole("button", { name: "Disabled href" });
    await expect(disabled).toBeDisabled();
    expect(await disabled.evaluate((el) => el.tagName)).toBe("BUTTON");

    const disabledTo = page.getByRole("button", { name: "Disabled to" });
    expect(await disabledTo.evaluate((el) => el.tagName)).toBe("BUTTON");
  });

  test("loading keeps the label and marks the button busy", async ({
    page,
  }) => {
    const btn = page.getByRole("button", { name: /Toggle loading/ });
    await btn.click();

    // The label is never replaced - the old component swapped it for "Loading".
    await expect(btn).toContainText("Toggle loading");
    await expect(btn).toHaveAttribute("aria-busy", "true");
    await expect(btn.locator(".btn__status")).toHaveText(/.+/);
  });

  test("keyboard focus is visible", async ({ page }) => {
    // The old component set outline:none with no replacement.
    const btn = page.getByRole("button", { name: "Rest", exact: true });
    await btn.focus();
    await page.keyboard.press("Tab");
    await page.keyboard.press("Shift+Tab");

    expect(await style(btn, "outline-width")).not.toBe("0px");
    expect(await style(btn, "outline-style")).not.toBe("none");
  });

  test("a group shares the standalone button surface", async ({ page }) => {
    // A group used an opaque fill while standalone buttons are translucent, so
    // it read as a different material.
    const standalone = page.getByRole("button", { name: "Rest", exact: true });
    const member = page
      .getByRole("button", { name: "Grid", exact: true })
      .first();

    expect(await style(member, "background-color")).toBe(
      await style(standalone, "background-color"),
    );
  });

  test("a group's label segment matches its members", async ({ page }) => {
    // The paginator puts "1 of 9" in a bare span; without its own surface the
    // group's track showed through and it read as a highlighted panel.
    const group = page.getByTestId("group-with-label");
    const label = group.locator(".btn-group__track > span");
    const member = group.getByRole("button", { name: "Next" });

    await expect(label).toHaveText("1 of 9");
    expect(await style(label, "background-color")).toBe(
      await style(member, "background-color"),
    );
    expect(Math.round((await box(label)).height)).toBe(
      Math.round((await box(member)).height),
    );
  });

  test("group members carry no chrome of their own", async ({ page }) => {
    // The container draws one border and one pair of caps for the whole control.
    const member = page
      .getByRole("button", { name: "Grid", exact: true })
      .first();

    expect(await style(member, "border-top-width")).toBe("0px");
    expect(await style(member, "border-radius")).toBe("0px");

    const capContent = await member.evaluate(
      (el) => getComputedStyle(el, "::before").content,
    );
    expect(capContent).toBe("none");
  });

  test("a dropdown inside a group is not rounded on both sides", async ({
    page,
  }) => {
    // The trigger is the first *and* last child of BtnDropdown's wrapper, so
    // position-based radii gave it a radius on both ends. The group's track
    // clips instead.
    const group = page.locator(".btn-group", {
      has: page.locator(".btn-dropdown"),
    });
    const trigger = group.locator(".btn-dropdown .btn");

    expect(await style(trigger, "border-radius")).toBe("0px");
  });

  test("the dropdown menu opens and its items are full width", async ({
    page,
  }) => {
    const trigger = page
      .locator(".btn-dropdown")
      .first()
      .getByRole("button")
      .first();
    await trigger.click();

    const menu = page.getByTestId("dropdown-list").first();
    await expect(menu).toBeVisible();

    const item = menu.getByRole("button", { name: "First action" });
    await expect(item).toBeVisible();
    expect(await style(item, "justify-content")).toBe("flex-start");
  });

  test("buttons carry no margin of their own", async ({ page }) => {
    // Spacing belongs to the container; `inline` existed only to cancel this.
    const btn = page.getByRole("button", { name: "Rest", exact: true });

    for (const side of ["top", "right", "bottom", "left"]) {
      expect(await style(btn, `margin-${side}`)).toBe("0px");
    }
  });
});
