import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import { h } from "vue";
import Component from "./index.vue";
import { AlertVariantsEnum } from "./types";

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
});
