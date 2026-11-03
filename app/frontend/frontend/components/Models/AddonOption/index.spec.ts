import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";

const mount = (props: Record<string, unknown> = {}) =>
  mountWithDefaults(Component, {
    props: { name: "Front Cargo Module", ...props },
  });

describe("AddonOption", () => {
  /**
   * A <button> may not contain a <button>, so the toggle is an overlay stretched
   * over the row and the stepper is its sibling. Nest them and the stepper stops
   * being reachable, which no visual check would show.
   */
  it("keeps the stepper outside the toggle button", async () => {
    const wrapper = await mount({ selected: true, count: 2, quantities: true });

    const toggle = wrapper.find("[data-test='addon-option-toggle']");

    expect(toggle.exists()).toBe(true);
    expect(toggle.find("button").exists()).toBe(false);
    expect(wrapper.find("[data-test='addon-option-increase']").exists()).toBe(
      true,
    );
  });

  it("offers no stepper unless quantities are wanted and the row is fitted", async () => {
    for (const props of [
      { selected: true, quantities: false },
      { selected: false, quantities: true },
      { selected: true, quantities: true, editable: false },
    ]) {
      const wrapper = await mount({ count: 2, ...props });

      expect(wrapper.find("[data-test='addon-option-increase']").exists()).toBe(
        false,
      );
    }
  });

  /**
   * The toggle covers the row, so its name has to carry everything the row shows
   * - a screen reader gets nothing from the pills otherwise.
   */
  it("names the row's figures and states on the toggle", async () => {
    const wrapper = await mount({
      contents: "2 × Weapons",
      count: 3,
      selected: true,
      quantities: true,
      badges: [
        { key: "cargo", label: "38 SCU" },
        {
          key: "status",
          label: "In Concept",
          variant: PillVariantsEnum.WARNING,
        },
      ],
    });

    const label = wrapper
      .find("[data-test='addon-option-toggle']")
      .attributes("aria-label");

    expect(label).toContain("Front Cargo Module");
    expect(label).toContain("2 × Weapons");
    expect(label).toContain("38 SCU");
    expect(label).toContain("In Concept");
    expect(label).toContain("3");
  });

  it("reports its pressed state", async () => {
    const on = await mount({ selected: true });
    const off = await mount({ selected: false });

    expect(
      on.find("[data-test='addon-option-toggle']").attributes("aria-pressed"),
    ).toBe("true");
    expect(
      off.find("[data-test='addon-option-toggle']").attributes("aria-pressed"),
    ).toBe("false");
  });

  // Nothing to press: the row is reporting what is fitted, not offering it.
  it("has no toggle at all when it cannot be edited", async () => {
    const wrapper = await mount({ editable: false });

    expect(wrapper.find("[data-test='addon-option-toggle']").exists()).toBe(
      false,
    );
    expect(wrapper.classes()).toContain("addon-option--static");
  });

  it("draws a glyph instead of a photograph when given one", async () => {
    const wrapper = await mount({ icon: "fa-duotone fa-layer-minus" });

    expect(wrapper.find("img").exists()).toBe(false);
    expect(wrapper.find(".addon-option__image--glyph").exists()).toBe(true);
  });

  it("falls back to the store-image placeholder", async () => {
    const wrapper = await mount({});

    expect(wrapper.find("img").attributes("src")).toBeTruthy();
  });

  it("renders a badge as a pill only when it carries a variant", async () => {
    const wrapper = await mount({
      badges: [
        { key: "cargo", label: "38 SCU" },
        { key: "fitted", label: "Fitted", variant: PillVariantsEnum.SUCCESS },
      ],
    });

    expect(wrapper.findAll("[data-test='pill']")).toHaveLength(1);
    expect(wrapper.find(".addon-option__figure").text()).toBe("38 SCU");
  });

  it("emits what the row was pressed for", async () => {
    const wrapper = await mount({ selected: true, count: 2, quantities: true });

    await wrapper.find("[data-test='addon-option-toggle']").trigger("click");
    await wrapper.find("[data-test='addon-option-increase']").trigger("click");
    await wrapper.find("[data-test='addon-option-decrease']").trigger("click");

    expect(wrapper.emitted("toggle")).toHaveLength(1);
    expect(wrapper.emitted("increase")).toHaveLength(1);
    expect(wrapper.emitted("decrease")).toHaveLength(1);
  });
});
