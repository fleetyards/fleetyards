import { describe, expect, it } from "vitest";
import { defineComponent, h } from "vue";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import type { HangarPlanModel } from "@/services/fyApi";
import Component from "./CardTitle.vue";

const ship = (name: string): HangarPlanModel => ({
  id: name,
  name,
  slug: name.toLowerCase(),
  onSale: true,
  ccuInto: "on_sale",
  ccuOutOf: "known",
});

const triggers = (wrapper: Awaited<ReturnType<typeof mountWithDefaults>>) =>
  wrapper.findAll(".hangar-flow-title__name").map((name) => name.text());

describe("Hangar/Planner/HangarFlow/CardTitle", () => {
  it("gives a custom name the stats of the ship it stands for", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { title: "Red Five", model: ship("Gladius") },
    });

    expect(triggers(wrapper)).toEqual(["Red Five"]);
  });

  it("gives every ship of an undecided slot its own stats", async () => {
    const props = {
      title: "Carrack / Polaris",
      model: ship("Carrack"),
      ships: [ship("Carrack"), ship("Polaris")],
    };
    const host = defineComponent({
      render: () => h("div", h(Component, props)),
    });
    const wrapper = await mountWithDefaults(host);

    expect(triggers(wrapper)).toEqual(["Carrack", "Polaris"]);
    expect(wrapper.text()).toContain("Carrack / Polaris");
  });

  it("stays plain text without a ship", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { title: "Nothing yet" },
    });

    expect(triggers(wrapper)).toEqual([]);
    expect(wrapper.text()).toBe("Nothing yet");
  });
});
