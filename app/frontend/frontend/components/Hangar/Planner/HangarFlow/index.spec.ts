import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  HangarPlanSlotStateEnum,
  HangarPlanStartKindEnum,
  HangarPlanVehicleStatusEnum,
  type HangarPlan,
  type HangarPlanComparison,
  type HangarPlanMetrics,
  type HangarPlanModel,
  type HangarPlanSlot,
} from "@/services/fyApi";
import Component from "./index.vue";

const model = (name: string): HangarPlanModel => ({
  id: name,
  name,
  slug: name.toLowerCase(),
  onSale: true,
  pledgePrice: 100,
});

const metrics = (): HangarPlanMetrics => ({
  total: 0,
  uniqueModelsCount: 0,
  manufacturerCount: 0,
  totalCrew: 0,
  totalCargo: 0,
  totalPledgeValue: 0,
  flightReadyCount: 0,
  classifications: [],
  sizes: [],
  productionStatuses: [],
  manufacturers: [],
});

const slot = (
  id: string,
  state: HangarPlanSlotStateEnum,
  attrs: Partial<HangarPlanSlot> = {},
): HangarPlanSlot => ({
  id,
  label: id,
  quantity: 1,
  position: 0,
  state,
  filters: {},
  candidates: [],
  ...attrs,
});

const carrack = model("Carrack");
const vulture = model("Vulture");

const plan: HangarPlan = {
  id: "plan",
  name: "Plan",
  basedOnAt: "2026-10-20T00:00:00Z",
  startingCredit: 0,
  buybackTokens: 0,
  vatRate: null,
  syncedBuybackTokens: null,
  shared: false,
  slotsCount: 3,
  createdAt: "2026-10-20T00:00:00Z",
  updatedAt: "2026-10-20T00:00:00Z",
  melts: [],
  slots: [
    slot("Explorer", HangarPlanSlotStateEnum.DECIDED, {
      candidates: [
        {
          id: "carrack",
          position: 0,
          model: carrack,
          modelModuleIds: [],
          modelUpgradeIds: [],
          matchesFilters: true,
          acquisitions: [
            {
              id: "bought",
              startKind: HangarPlanStartKindEnum.STORE,
              startModel: carrack,
              price: 600,
              sourceMissing: false,
              usesBuybackToken: false,
              steps: [],
            },
          ],
        },
      ],
    }),
    slot("Salvage", HangarPlanSlotStateEnum.DECIDED, {
      candidates: [
        {
          id: "vulture",
          position: 0,
          model: vulture,
          modelModuleIds: [],
          modelUpgradeIds: [],
          matchesFilters: true,
          acquisitions: [
            {
              id: "kept",
              startKind: HangarPlanStartKindEnum.OWNED,
              sourceVehicleId: "vehicle-vulture",
              startModel: vulture,
              price: 0,
              sourceMissing: false,
              usesBuybackToken: false,
              steps: [],
            },
          ],
        },
      ],
    }),
    slot("Mining", HangarPlanSlotStateEnum.UNDECIDED),
  ],
};

const comparison: HangarPlanComparison = {
  vehicles: [
    {
      vehicleId: "vehicle-aurora",
      model: model("Aurora MR"),
      status: HangarPlanVehicleStatusEnum.UNASSIGNED,
    },
    {
      vehicleId: "vehicle-titan",
      model: model("Avenger Titan"),
      status: HangarPlanVehicleStatusEnum.MELTED,
    },
    {
      vehicleId: "vehicle-vulture",
      model: vulture,
      status: HangarPlanVehicleStatusEnum.KEPT,
    },
  ],
  models: [],
  gaps: [],
  metrics: { live: metrics(), plan: metrics() },
};

const rowTests = (wrapper: Awaited<ReturnType<typeof mountWithDefaults>>) =>
  wrapper
    .findAll(".hangar-flow__row:not(.hangar-flow__row--head)")
    .map((row) => row.attributes("data-test"));

describe("Hangar/Planner/HangarFlow", () => {
  it("lists what the plan settles first and folds the ships it has no use for", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { plan, comparison },
    });

    // Decided, then bought, then undecided, then melted; not in plan is folded.
    expect(rowTests(wrapper)).toEqual([
      "hangar-plan-vehicle-status",
      "hangar-plan-flow-purchase",
      "hangar-plan-flow-undecided",
      "hangar-plan-vehicle-status",
    ]);
    expect(wrapper.text()).not.toContain("Aurora MR");

    const toggle = wrapper.find(
      '[data-test="hangar-plan-flow-toggle-unassigned"]',
    );
    expect(toggle.text()).toContain("1 ship not in the plan");

    await toggle.trigger("click");
    expect(wrapper.text()).toContain("Aurora MR");
  });
});
