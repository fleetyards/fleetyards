import { describe, expect, it } from "vitest";
import { flushPromises, type VueWrapper } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import Component from "./index.vue";
import { useFleetStore } from "@/frontend/stores/fleet";

const toggle = (wrapper: VueWrapper, name: string) =>
  wrapper
    .findAllComponents({ name: "FormToggle" })
    .find((component) => component.props("name") === name);

describe("FleetDisplayOptionsModal", () => {
  // The public fleet list opens the same modal but has no metrics bar.
  it("offers the metric switches only where the metrics are shown", async () => {
    const wrapper = await mountWithDefaults(Component);

    expect(toggle(wrapper, "money")).toBeUndefined();
    expect(toggle(wrapper, "credits")).toBeUndefined();
  });

  it("hides the pledge value without hiding the in-game value", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { metrics: true },
    });
    const fleetStore = useFleetStore();

    toggle(wrapper, "money")!.vm.$emit("update:modelValue", false);
    await flushPromises();

    expect(fleetStore.money).toBe(false);
    expect(fleetStore.credits).toBe(true);

    toggle(wrapper, "credits")!.vm.$emit("update:modelValue", false);
    toggle(wrapper, "money")!.vm.$emit("update:modelValue", true);
    await flushPromises();

    expect(fleetStore.money).toBe(true);
    expect(fleetStore.credits).toBe(false);
  });
});
