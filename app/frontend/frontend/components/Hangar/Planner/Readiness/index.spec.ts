import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  HangarPlanSlotStateEnum,
  type HangarPlanSlot,
  type HangarPlanSlotCost,
} from "@/services/fyApi";
import Component from "./index.vue";

const slot = (
  id: string,
  state: HangarPlanSlotStateEnum,
  quantity = 1,
): HangarPlanSlot => ({
  id,
  label: id,
  quantity,
  position: 0,
  state,
  filters: {},
  candidates: [],
});

const cost = (slotId: string, unresolvedCount: number): HangarPlanSlotCost => ({
  slotId,
  state: HangarPlanSlotStateEnum.DECIDED,
  minCost: 0,
  maxCost: 0,
  unresolvedCount,
  complete: unresolvedCount === 0,
});

describe("Hangar/Planner/Readiness", () => {
  it("counts every ship of the plan and names each slot that needs work", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        slots: [
          slot("Escort", HangarPlanSlotStateEnum.DECIDED, 2),
          slot("Mining", HangarPlanSlotStateEnum.UNDECIDED),
          slot("Explorer", HangarPlanSlotStateEnum.OPEN),
        ],
        costs: [cost("Escort", 1)],
      },
    });

    expect(wrapper.text()).toContain("1 of 4 ships have a route");

    const issues = wrapper.findAll('[data-test="hangar-plan-readiness-issue"]');
    expect(issues.map((issue) => issue.text())).toEqual([
      "Escort: 1 ship without a route",
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
