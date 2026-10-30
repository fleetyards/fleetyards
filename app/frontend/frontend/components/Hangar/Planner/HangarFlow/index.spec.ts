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
  upgradable: true,
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
              routeComplete: true,
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
              routeComplete: true,
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
    // Keeping or upgrading a ship is picking where it ends up.
    expect(pending.find('[data-test="hangar-plan-decide-keep"]').exists()).toBe(
      false,
    );

    await pending
      .find('[data-test="hangar-plan-decide-change"]')
      .trigger("click");
    await change
      .find('[data-test="hangar-plan-decide-pending"]')
      .trigger("click");
    await pending
      .find('[data-test="hangar-plan-flow-pick-end"]')
      .trigger("click");

    expect(wrapper.emitted("decide")).toEqual([
      ["vehicle-gladius", "change"],
      ["vehicle-cutlass", "pending"],
    ]);
    expect(wrapper.emitted("end")).toEqual([
      [
        {
          startName: "Gladius",
          startModel: model("Gladius"),
          vehicleId: "vehicle-gladius",
        },
      ],
    ]);
  });

  it("picks a route's start on the left and its end on the right", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { plan, comparison },
    });

    const purchase = wrapper.find('[data-test="hangar-plan-flow-purchase"]');
    await purchase
      .find('[data-test="hangar-plan-flow-pick-start"]')
      .trigger("click");
    await purchase
      .find('[data-test="hangar-plan-flow-pick-end"]')
      .trigger("click");

    const [[start]] = wrapper.emitted("start") as [
      [
        {
          slot: { id: string };
          candidate: { id: string };
          acquisition: { id: string };
        },
      ],
    ];
    expect([start.slot.id, start.candidate.id, start.acquisition.id]).toEqual([
      "Explorer",
      "carrack",
      "bought",
    ]);

    const [[end]] = wrapper.emitted("end") as [
      [{ acquisition: { id: string }; slot: HangarPlanSlot }],
    ];
    expect([end.acquisition.id, end.slot.id]).toEqual(["bought", "Explorer"]);
  });

  it("plans the route from the middle once start and end differ", async () => {
    const cutlass = model("Cutlass Black");
    const [explorer, salvage, mining] = plan.slots;
    const unrouted: HangarPlan = {
      ...plan,
      slots: [
        explorer,
        {
          ...salvage,
          candidates: [
            {
              ...salvage.candidates[0],
              acquisitions: [
                {
                  ...salvage.candidates[0].acquisitions[0],
                  sourceVehicleId: "vehicle-cutlass",
                  startModel: cutlass,
                  routeComplete: false,
                },
              ],
            },
          ],
        },
        mining,
      ],
    };
    const wrapper = await mountWithDefaults(Component, {
      props: {
        plan: unrouted,
        comparison: {
          ...comparison,
          vehicles: [
            {
              vehicleId: "vehicle-cutlass",
              model: cutlass,
              status: HangarPlanVehicleStatusEnum.UNROUTED,
              targetModel: vulture,
            },
          ],
        },
      },
    });

    const row = wrapper.find('[data-test="hangar-plan-vehicle-unrouted"]');
    expect(row.text()).toContain("Cutlass Black");
    expect(row.text()).toContain("Plan route");
    expect(row.text()).toContain("Vulture");

    await row.find('[data-test="hangar-plan-flow-route"]').trigger("click");

    const [[candidate, acquisition]] = wrapper.emitted("route") as [
      [{ id: string }, { id: string }],
    ];
    expect([candidate.id, acquisition.id]).toEqual(["vulture", "kept"]);
  });

  it("offers a start for a slot's units without one, and ships for an empty slot", async () => {
    const empty = slot("Hauler", HangarPlanSlotStateEnum.OPEN);
    const [explorer, ...rest] = plan.slots;
    const short = { ...explorer, quantity: 2 };
    const wrapper = await mountWithDefaults(Component, {
      props: {
        plan: { ...plan, slots: [short, ...rest, empty] },
        comparison: {
          ...comparison,
          gaps: [
            {
              slotId: "Explorer",
              label: "Explorer",
              model: carrack,
              count: 1,
            },
          ],
        },
      },
    });

    const gap = wrapper.find('[data-test="hangar-plan-gap"]');
    await gap
      .find('[data-test="hangar-plan-flow-pick-start"]')
      .trigger("click");
    await gap.find('[data-test="hangar-plan-flow-route"]').trigger("click");
    await gap.find('[data-test="hangar-plan-flow-edit-slot"]').trigger("click");
    await wrapper
      .find('[data-test="hangar-plan-flow-open"]')
      .find('[data-test="hangar-plan-flow-pick"]')
      .trigger("click");

    const [[start]] = wrapper.emitted("start") as [
      [
        {
          slot: { id: string };
          candidate: { id: string };
          acquisition?: unknown;
        },
      ],
    ];
    expect([start.slot.id, start.candidate.id, start.acquisition]).toEqual([
      "Explorer",
      "carrack",
      undefined,
    ]);
    expect((wrapper.emitted("route") as [[{ id: string }]])[0][0].id).toEqual(
      "carrack",
    );
    expect(wrapper.emitted("edit")).toEqual([[short]]);
    expect(wrapper.emitted("pick")).toEqual([[empty]]);
  });

  it("picks a start for an undecided slot, and opens its ships from the card", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { plan, comparison },
    });

    const undecided = wrapper.find('[data-test="hangar-plan-flow-undecided"]');
    expect(
      undecided.find('[data-test="hangar-plan-flow-route"]').exists(),
    ).toBe(false);

    await undecided
      .find('[data-test="hangar-plan-flow-pick-start"]')
      .trigger("click");
    await undecided
      .find('[data-test="hangar-plan-flow-edit-slot"]')
      .trigger("click");

    expect(wrapper.emitted("start")).toEqual([[{ slot: plan.slots[2] }]]);
    expect(wrapper.emitted("edit")).toEqual([[plan.slots[2]]]);
  });

  it("asks for another start where no upgrade leads to the slot's ship", async () => {
    const idris = { ...model("Idris-P"), pledgePrice: 1500, upgradable: false };
    const [explorer, ...rest] = plan.slots;
    const wrapper = await mountWithDefaults(Component, {
      props: {
        plan: {
          ...plan,
          slots: [
            {
              ...explorer,
              candidates: [
                {
                  ...explorer.candidates[0],
                  model: idris,
                  acquisitions: [
                    {
                      ...explorer.candidates[0].acquisitions[0],
                      routeComplete: false,
                    },
                  ],
                },
              ],
            },
            ...rest,
          ],
        },
        comparison,
      },
    });

    const row = wrapper.find('[data-test="hangar-plan-flow-unrouted"]');
    expect(row.text()).toContain("No upgrade possible");

    await row.find('[data-test="hangar-plan-flow-route"]').trigger("click");

    expect(wrapper.emitted("route")).toBeUndefined();
    expect(
      (wrapper.emitted("start") as [[{ acquisition: { id: string } }]])[0][0]
        .acquisition.id,
    ).toEqual("bought");
  });

  it("only melts a ship RSI sells no upgrades for once it should change", async () => {
    const kraken = { ...model("Kraken"), pledgePrice: 1650, upgradable: false };
    const wrapper = await mountWithDefaults(Component, {
      props: {
        plan,
        comparison: {
          ...comparison,
          vehicles: [
            {
              vehicleId: "vehicle-kraken",
              model: kraken,
              status: HangarPlanVehicleStatusEnum.CHANGE,
            },
          ],
        },
      },
    });

    const row = wrapper.find('[data-test="hangar-plan-vehicle-review"]');
    expect(row.text()).toContain("Should change");
    expect(row.text()).toContain("it can only be melted");
    expect(row.find('[data-test="hangar-plan-flow-pick-end"]').exists()).toBe(
      false,
    );
    expect(
      row
        .findAll('[data-test^="hangar-plan-decide-"]')
        .map((button) => button.attributes("data-test")),
    ).toEqual(["hangar-plan-decide-melt", "hangar-plan-decide-pending"]);
  });
});
