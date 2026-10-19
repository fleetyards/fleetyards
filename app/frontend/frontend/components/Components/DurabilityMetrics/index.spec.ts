import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import Component from "./index.vue";

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

describe("ComponentDurabilityMetrics", () => {
  // A crafted part's integrity, against the catalogue's.
  it("marks the figures crafting moved", async () => {
    wrapper = await mountWithDefaults(Component, {
      props: {
        durability: { health: 600, mass: 9 },
        stock: { health: 500, mass: 9 },
      },
    });

    const changed = wrapper.findAll(".durability-metrics__changed");

    expect(changed).toHaveLength(1);
    expect(changed[0].text()).toContain("600");
  });

  it("marks nothing without a catalogue record to compare with", async () => {
    wrapper = await mountWithDefaults(Component, {
      props: { durability: { health: 600, mass: 9 } },
    });

    expect(wrapper.findAll(".durability-metrics__changed")).toHaveLength(0);
  });
});
