import { test, expect } from "../support/commands";

/*
 * Every control that can be invalid has to say so where it can be seen. Two of
 * them did not: FormCheckbox and FormToggle surfaced a validation error through
 * the hover tooltip alone - nothing for someone not using a mouse, and nothing
 * at all for assistive tech, which is the same failure the filter chips had with
 * colour.
 *
 * Asserted against visual-tests/forms/ErrorStates.vue, which stands every
 * bindable control in one vee-validate form and validates on mount, so the
 * invalid state is on screen without anyone typing.
 */

// Each control marks itself with its own class, so the wrappers are listed
// rather than matched by a shared pattern - there isn't one.
const invalid = [
  { hook: "input-wrapper-handle", marker: "base-input--with-error" },
  { hook: "input-wrapper-contact", marker: "base-input--with-error" },
  { hook: "input-wrapper-boughtAt", marker: "base-input--with-error" },
];

test.describe("Form states", () => {
  // Scoped to the rig: forms.vue has fields of its own carrying some of the same
  // names, so an unscoped hook matches two elements.
  const rig = (page: import("@playwright/test").Page) =>
    page.getByTestId("error-states");

  test.beforeEach(async ({ page }) => {
    await page.goto("/visual-tests/forms/");
    await expect(rig(page)).toBeVisible();
  });

  test("an invalid field carries a visible marker", async ({ page }) => {
    for (const { hook, marker } of invalid) {
      await expect(
        rig(page).getByTestId(hook),
        `${hook} should carry ${marker}`,
      ).toHaveClass(new RegExp(marker));
    }
  });

  test("an invalid checkbox and toggle are marked, not just tooltipped", async ({
    page,
  }) => {
    // The whole point: a tooltip is not a state.
    const checkbox = rig(page).locator(".base-checkbox--with-error").first();
    const toggle = rig(page).locator(".form-toggle--with-error").first();

    await expect(checkbox).toBeVisible();
    await expect(toggle).toBeVisible();

    // And the marker is not colour alone - assistive tech gets told too.
    await expect(checkbox.locator("input")).toHaveAttribute(
      "aria-invalid",
      "true",
    );
    await expect(toggle.locator("input")).toHaveAttribute(
      "aria-invalid",
      "true",
    );
  });

  test("a disabled control renders as disabled, not merely styled", async ({
    page,
  }) => {
    // `disabled` on the wrong element is how a control stays operable while
    // looking otherwise - the defect Btn had with anchors.
    for (const name of ["disabledDate", "disabledImage", "disabledDateTime"]) {
      const wrapper = page.getByTestId(`input-wrapper-${name}`);
      if ((await wrapper.count()) === 0) continue;
      await expect(wrapper.locator("input").first()).toBeDisabled();
    }
  });
});
