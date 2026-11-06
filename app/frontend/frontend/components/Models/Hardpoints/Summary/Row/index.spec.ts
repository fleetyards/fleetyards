import { describe, expect, it } from "vitest";
import { provide as provideValue } from "vue";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  HardpointCategoryEnum,
  HardpointSourceEnum,
  type Hardpoint,
} from "@/services/fyApi";
import { type MinimalRow } from "../../summaryRows";
import Component from "./index.vue";

const thruster = (maxSize: number) =>
  ({
    id: `thruster-${maxSize}`,
    name: "hardpoint_thruster",
    source: HardpointSourceEnum.GAME_FILES,
    category: HardpointCategoryEnum.MANEUVERING_THRUSTERS,
    maxSize,
    component: { typeData: { thrustCapacity: 1000 } },
  }) as unknown as Hardpoint;

const mountRow = (row: Partial<MinimalRow>, provide = {}) =>
  mountWithDefaults(
    defineComponent({
      components: { Row: Component },
      setup() {
        Object.entries(provide).forEach(([key, value]) => {
          provideValue(key, value);
        });

        return { row: { key: "row", total: false, relatedIds: [], ...row } };
      },
      template: "<Row :row='row' />",
    }),
  );

describe("HardpointsSummaryRow", () => {
  it("badges a total row only when its thrusters share a size", async () => {
    const same = await mountRow({
      total: true,
      hardpoints: [thruster(1), thruster(1)],
    });
    const mixed = await mountRow({
      total: true,
      hardpoints: [thruster(1), thruster(2)],
    });

    expect(same.find(".minimal-row__size").text()).toBe("S1");
    expect(mixed.find(".minimal-row__size").exists()).toBe(false);
  });

  it("names the module a reader picked, not the slot's own", async () => {
    const slot = {
      id: "front",
      groupKey: "front",
      name: "hardpoint_front_module",
      source: HardpointSourceEnum.GAME_FILES,
      category: HardpointCategoryEnum.MODULE,
      component: { name: "Cargo Module" },
    } as unknown as Hardpoint;

    const wrapper = await mountRow(
      { hardpoints: [slot] },
      { equippedModules: ref({ front: { name: "Torpedo Module" } }) },
    );

    expect(wrapper.text()).toContain("Torpedo Module");
    expect(wrapper.text()).not.toContain("Cargo Module");
  });
});
