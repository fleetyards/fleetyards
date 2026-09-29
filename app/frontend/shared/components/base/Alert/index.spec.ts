import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import { h } from "vue";
import Component from "./index.vue";
import { AlertSizesEnum, AlertVariantsEnum } from "./types";

describe("BaseAlert", () => {
  it("draws the variant's icon and tint", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { variant: AlertVariantsEnum.WARNING },
      slots: { default: () => [h("span", "Heads up")] },
    });

    expect(wrapper.classes()).toContain("base-alert--warning");
    expect(wrapper.find(".fa-triangle-exclamation").exists()).toBe(true);
    expect(wrapper.text()).toContain("Heads up");
  });

  it("puts a title on its own line above the text", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { title: "Not protected" },
      slots: { default: () => [h("span", "Details")] },
    });

    expect(wrapper.find('[data-test="alert-title"]').text()).toBe(
      "Not protected",
    );
  });

  it("renders actions only when given", async () => {
    const plain = await mountWithDefaults(Component, {
      slots: { default: () => [h("span", "Note")] },
    });
    expect(plain.find(".base-alert__actions").exists()).toBe(false);

    const withAction = await mountWithDefaults(Component, {
      slots: {
        default: () => [h("span", "Note")],
        actions: () => [h("button", "Go")],
      },
    });
    expect(withAction.find(".base-alert__actions button").exists()).toBe(true);
  });

  it("asks to be dismissed rather than hiding itself", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { dismissible: true },
      slots: { default: () => [h("span", "Tip")] },
    });

    await wrapper.find('[data-test="alert-dismiss"]').trigger("click");

    expect(wrapper.emitted("dismiss")).toHaveLength(1);
    expect(wrapper.find('[data-test="alert"]').exists()).toBe(true);
  });

  it("offers a compact size", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { size: AlertSizesEnum.COMPACT },
      slots: { default: () => [h("span", "Small")] },
    });

    expect(wrapper.classes()).toContain("base-alert--compact");
  });
});
