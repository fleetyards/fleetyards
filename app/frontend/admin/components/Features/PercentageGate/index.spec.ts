import { describe, it, expect, vi } from "vitest";
import { mount } from "@vue/test-utils";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

import PercentageGate from "./index.vue";

const mountGate = (value = 25) =>
  mount(PercentageGate, {
    props: { name: "actors", label: "Share of users", value },
    global: {
      stubs: {
        Slider: {
          name: "Slider",
          props: ["modelValue"],
          emits: ["update:modelValue"],
          template: "<div />",
        },
        FormInput: {
          name: "FormInput",
          props: ["modelValue"],
          emits: ["update:modelValue"],
          template: "<input :value='modelValue' />",
        },
        Btn: {
          props: ["disabled"],
          emits: ["click"],
          template:
            "<button :disabled='disabled' @click=\"$emit('click')\"><slot /></button>",
        },
      },
    },
  });

const APPLY = '[data-test="percentage-apply-actors"]';

describe("FeaturePercentageGate", () => {
  it("sends nothing while the slider moves", async () => {
    const wrapper = mountGate();

    wrapper.findComponent({ name: "Slider" }).vm.$emit("update:modelValue", 60);
    await nextTick();

    expect(wrapper.emitted("apply")).toBeUndefined();
    expect(
      wrapper.findComponent({ name: "FormInput" }).props("modelValue"),
    ).toBe(60);
  });

  it("applies the draft once Apply is pressed", async () => {
    const wrapper = mountGate();

    wrapper.findComponent({ name: "Slider" }).vm.$emit("update:modelValue", 60);
    await nextTick();
    await wrapper.find(APPLY).trigger("click");

    expect(wrapper.emitted("apply")).toEqual([[60]]);
  });

  it("keeps Apply disabled until the draft differs", async () => {
    const wrapper = mountGate();

    expect(wrapper.find(APPLY).attributes("disabled")).toBeDefined();

    wrapper
      .findComponent({ name: "FormInput" })
      .vm.$emit("update:modelValue", "40");
    await nextTick();

    expect(wrapper.find(APPLY).attributes("disabled")).toBeUndefined();
  });

  it("clamps a typed value to a percentage", async () => {
    const wrapper = mountGate();

    wrapper
      .findComponent({ name: "FormInput" })
      .vm.$emit("update:modelValue", "250");
    await nextTick();
    await wrapper.find(APPLY).trigger("click");

    expect(wrapper.emitted("apply")).toEqual([[100]]);
  });

  it("follows the flag when it changes underneath", async () => {
    const wrapper = mountGate();

    await wrapper.setProps({ value: 50 });

    expect(wrapper.findComponent({ name: "Slider" }).props("modelValue")).toBe(
      50,
    );
  });
});
