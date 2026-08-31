import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";

/*
 * The message below a checkbox is rendered only when there is one, unlike a
 * field's, which holds its place so an error cannot move the page.
 *
 * Reserving it here was a regression with two faces, and neither was visible in
 * the component on its own: it doubled a 24px control's height, which moved the
 * middle of the notification list's row selector off the box and onto the empty
 * message -- so the admin bulk-archive test clicked the message and counted no
 * selection -- and it left 24px of dead space under the login form's toggle.
 */
describe("FormCheckbox", () => {
  it("renders no message element while the field is valid", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { name: "terms", label: "Accept terms" },
    });

    expect(wrapper.find(".base-checkbox__error").exists()).toBe(false);
  });

  it("keeps the label as the whole of the control's height", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { name: "terms", label: "Accept terms" },
    });

    // Nothing renders after the label, so the component's box is the control's
    // box and its middle is on the box a click has to land on.
    const children = wrapper.element.children;

    expect(children[children.length - 1].tagName).toBe("LABEL");
  });
});
