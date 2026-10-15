import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import type { VehicleLoadoutMinimal } from "@/services/fyApi";
import Component from "./index.vue";

const loadout = (overrides: Partial<VehicleLoadoutMinimal> = {}) =>
  ({
    id: "l1",
    name: "Hauler",
    active: true,
    kind: "fleetyards",
    items: [],
    ...overrides,
  }) as VehicleLoadoutMinimal;

describe("LoadoutMarker", () => {
  it("links a linked build away", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        loadout: loadout({
          kind: "link",
          url: "https://erkul.games/loadout/x",
          urlSource: "erkul",
        }),
      },
    });
    const marker = wrapper.get("[data-test='loadout-marker']");

    expect(marker.element.tagName).toBe("A");
    await marker.trigger("click");
    expect(wrapper.emitted("open")).toBeUndefined();
  });

  it("asks to show a fleetyards loadout", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { loadout: loadout() },
    });
    const marker = wrapper.get("[data-test='loadout-marker']");

    expect(marker.element.tagName).toBe("BUTTON");
    await marker.trigger("click");
    expect(wrapper.emitted("open")).toHaveLength(1);
  });
});
