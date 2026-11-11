import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  HangarPlanSlotStateEnum,
  type HangarPlanSlot,
  type HangarPlanSlotCost,
} from "@/services/fyApi";
import Component from "./index.vue";

const slot = (id: string, state: HangarPlanSlotStateEnum): HangarPlanSlot => ({
  id,
  label: id,
  position: 0,
  state,
  filters: {},
  starts: [],
  candidates: [],
});

const cost = (slotId: string, unresolvedCount: number): HangarPlanSlotCost => ({
  slotId,
  state: HangarPlanSlotStateEnum.DECIDED,
  minCost: 0,
  maxCost: 0,
  storeCostMin: 0,
  storeCost: 0,
  unresolvedCount,
  complete: unresolvedCount === 0,
});

describe("Hangar/Planner/Readiness", () => {
  it("counts every ship of the plan and names each slot that needs work", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        slots: [
          slot("Escort", HangarPlanSlotStateEnum.DECIDED),
          slot("Wingman", HangarPlanSlotStateEnum.DECIDED),
          slot("Mining", HangarPlanSlotStateEnum.UNDECIDED),
          slot("Explorer", HangarPlanSlotStateEnum.OPEN),
        ],
        costs: [cost("Escort", 0), cost("Wingman", 1)],
      },
    });

    expect(wrapper.text()).toContain("1 of 4 ships have a route");

    const issues = wrapper.findAll('[data-test="hangar-plan-readiness-issue"]');
    expect(issues.map((issue) => issue.text())).toEqual([
      "Wingman: 1 ship without a route",
      "Mining is undecided",
      "Explorer has no ship",
    ]);
  });

  it("names nothing once every ship has a route", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        slots: [slot("Hauler", HangarPlanSlotStateEnum.DECIDED)],
        costs: [cost("Hauler", 0)],
      },
    });

    expect(wrapper.text()).toContain("1 of 1 ship has a route");
    expect(
      wrapper.find('[data-test="hangar-plan-readiness-issue"]').exists(),
    ).toBe(false);
  });
});
