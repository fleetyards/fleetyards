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
  vehicleMarks: [],
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
  it("lists the slots first and folds the ships kept or left out", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { plan, comparison },
    });

    // Slots in the plan's order, then the melted ship; kept and left out fold.
    expect(rowTests(wrapper)).toEqual([
      "hangar-plan-flow-purchase",
      "hangar-plan-flow-undecided",
      "hangar-plan-vehicle-status",
    ]);
    expect(wrapper.text()).not.toContain("Aurora MR");
    expect(wrapper.text()).not.toContain("Vulture");
    expect(
      wrapper.find('[data-test="hangar-plan-flow-toggle-kept"]').text(),
    ).toContain("1 kept as it is");

    const toggle = wrapper.find(
      '[data-test="hangar-plan-flow-toggle-unassigned"]',
    );
    expect(toggle.text()).toContain("1 ship not in the plan");

    await toggle.trigger("click");
    expect(wrapper.text()).toContain("Aurora MR");
  });

  it("keeps each ship in its hangar place, whatever was decided for it", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        plan,
        comparison: {
          ...comparison,
          vehicles: [
            ...comparison.vehicles,
            {
              vehicleId: "vehicle-cutlass",
              model: model("Cutlass Black"),
              status: HangarPlanVehicleStatusEnum.CHANGE,
            },
            {
              vehicleId: "vehicle-gladius",
              model: model("Gladius"),
              status: HangarPlanVehicleStatusEnum.PENDING,
            },
          ],
        },
      },
    });

    // The melted Titan comes before both, as it does in the hangar.
    expect(rowTests(wrapper)).toEqual([
      "hangar-plan-flow-purchase",
      "hangar-plan-flow-undecided",
      "hangar-plan-vehicle-status",
      "hangar-plan-vehicle-review",
      "hangar-plan-vehicle-review",
    ]);

    const [change, pending] = wrapper.findAll(
      '[data-test="hangar-plan-vehicle-review"]',
    );
    expect(change.text()).toContain("Should change");
    expect(
      change.find('[data-test="hangar-plan-decide-change"]').exists(),
    ).toBe(false);
    expect(pending.text()).toContain("Needs a decision");

    await pending
      .find('[data-test="hangar-plan-decide-keep"]')
      .trigger("click");
    await change
      .find('[data-test="hangar-plan-decide-pending"]')
      .trigger("click");

    expect(wrapper.emitted("decide")).toEqual([
      ["vehicle-gladius", "keep"],
      ["vehicle-cutlass", "pending"],
    ]);
  });

  it("offers a route from the left and ships for an empty slot on the right", async () => {
    const empty = slot("Hauler", HangarPlanSlotStateEnum.OPEN);
    const wrapper = await mountWithDefaults(Component, {
      props: { plan: { ...plan, slots: [...plan.slots, empty] }, comparison },
    });

    await wrapper
      .find('[data-test="hangar-plan-flow-toggle-kept"]')
      .trigger("click");
    const kept = wrapper
      .findAll('[data-test="hangar-plan-vehicle-status"]')
      .find((row) => row.text().includes("Vulture"));
    await kept!
      .findAll('[role="cell"]')[0]
      .find('[data-test="hangar-plan-flow-edit-route"]')
      .trigger("click");

    await wrapper
      .find('[data-test="hangar-plan-flow-open"]')
      .find('[data-test="hangar-plan-flow-pick"]')
      .trigger("click");

    const [[candidate, acquisition]] = wrapper.emitted("route") as [
      [{ id: string }, { id: string }],
    ];
    expect([candidate.id, acquisition.id]).toEqual(["vulture", "kept"]);
    expect(wrapper.emitted("pick")).toEqual([[empty]]);
  });

  it("opens a slot from its card, and plans no route until a ship is chosen", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { plan, comparison },
    });

    const undecided = wrapper.find('[data-test="hangar-plan-flow-undecided"]');
    expect(
      undecided.find('[data-test="hangar-plan-flow-add-route"]').exists(),
    ).toBe(false);

    await undecided
      .find('[data-test="hangar-plan-flow-edit-slot"]')
      .trigger("click");
    await wrapper
      .find('[data-test="hangar-plan-flow-purchase"]')
      .find('[data-test="hangar-plan-flow-edit-slot"]')
      .trigger("click");

    expect(wrapper.emitted("edit")).toEqual([[plan.slots[2]], [plan.slots[0]]]);
  });
});
