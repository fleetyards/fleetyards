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
  type HangarPlanSummary,
} from "@/services/fyApi";
import type {
  HangarFlowTab,
  HangarFlowTarget,
} from "@/frontend/components/Hangar/Planner/HangarFlow/types";
import Component from "./index.vue";

const model = (name: string): HangarPlanModel => ({
  id: name,
  name,
  slug: name.toLowerCase(),
  onSale: true,
  ccuInto: "on_sale",
  ccuOutOf: "known",
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
  starts: [],
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
  syncedStoreCredit: null,
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
      pledgeShips: [],
      pledgeItems: [],
      model: model("Aurora MR"),
      status: HangarPlanVehicleStatusEnum.UNASSIGNED,
    },
    {
      vehicleId: "vehicle-titan",
      pledgeShips: [],
      pledgeItems: [],
      model: model("Avenger Titan"),
      status: HangarPlanVehicleStatusEnum.MELTED,
    },
    {
      vehicleId: "vehicle-vulture",
      pledgeShips: [],
      pledgeItems: [],
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

// What the flow asked the ship panel to open, by tab, in the shape each side
// carries.
const opened = (
  wrapper: Awaited<ReturnType<typeof mountWithDefaults>>,
  tab: HangarFlowTab,
): unknown => {
  const targets = ((wrapper.emitted("open") ?? []) as [HangarFlowTarget][])
    .map(([target]) => target)
    .filter((target) => target.tab === tab);
  if (!targets.length) return undefined;

  return targets.map((target) => {
    switch (tab) {
      case "start":
        return [target.start];
      case "end":
        return [target.end];
      case "route":
        return [target.route?.candidate, target.route?.acquisition];
      default:
        return [target.slot];
    }
  });
};

describe("Hangar/Planner/HangarFlow", () => {
  it("lists the slots first and folds the ships kept or left out", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { plan, comparison },
    });

    // What needs a decision, then the finished route; the rest folds.
    expect(rowTests(wrapper)).toEqual([
      "hangar-plan-flow-undecided",
      "hangar-plan-flow-purchase",
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

    const melted = wrapper.find('[data-test="hangar-plan-flow-toggle-melted"]');
    expect(melted.text()).toContain("1 melted");
    expect(wrapper.text()).not.toContain("Avenger Titan");
    await melted.trigger("click");
    expect(wrapper.text()).toContain("Avenger Titan");

    await toggle.trigger("click");
    expect(wrapper.text()).toContain("Aurora MR");
  });

  it("takes a kept or melted ship back to undecided in one click", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        plan: {
          ...plan,
          melts: [
            {
              id: "melt-titan",
              vehicleId: "vehicle-titan",
              model: model("Avenger Titan"),
              value: 50,
              estimated: false,
              vehicleMissing: false,
              pledgeShips: [],
              pledgeItems: [],
            },
          ],
        },
        comparison,
      },
    });

    await wrapper
      .find('[data-test="hangar-plan-flow-toggle-kept"]')
      .trigger("click");
    await wrapper
      .find('[data-test="hangar-plan-flow-toggle-melted"]')
      .trigger("click");

    const [kept, melted] = wrapper
      .findAll('[data-test="hangar-plan-vehicle-status"]')
      .filter((row) =>
        row.find('[data-test="hangar-plan-decide-pending"]').exists(),
      );
    expect(kept.text()).toContain("Vulture");
    // Keeping a ship costs nothing, which "Kept" already says.
    expect(kept.text()).not.toContain("Free");
    expect(melted.text()).toContain("Avenger Titan");

    await kept
      .find('[data-test="hangar-plan-decide-pending"]')
      .trigger("click");
    await melted
      .find('[data-test="hangar-plan-decide-pending"]')
      .trigger("click");

    expect(wrapper.emitted("decide")).toEqual([
      ["vehicle-vulture", "pending"],
      ["vehicle-titan", "pending"],
    ]);
  });

  it("picks a start for a slot with no ship yet", async () => {
    const empty = slot("Hauler", HangarPlanSlotStateEnum.OPEN);
    const wrapper = await mountWithDefaults(Component, {
      props: {
        plan: { ...plan, slots: [empty] },
        comparison: { ...comparison, vehicles: [] },
      },
    });

    const row = wrapper.find('[data-test="hangar-plan-flow-open"]');
    expect(row.text()).toContain("Pick a start");
    await row
      .find('[data-test="hangar-plan-flow-pick-start"]')
      .trigger("click");

    expect(opened(wrapper, "start")).toEqual([[{ slot: empty }]]);
  });

  it("lists ships needing a decision before ships that should change", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        plan,
        comparison: {
          ...comparison,
          vehicles: [
            ...comparison.vehicles,
            {
              vehicleId: "vehicle-cutlass",
              pledgeShips: [],
              pledgeItems: [],
              model: model("Cutlass Black"),
              status: HangarPlanVehicleStatusEnum.CHANGE,
            },
            {
              vehicleId: "vehicle-gladius",
              pledgeShips: [],
              pledgeItems: [],
              model: model("Gladius"),
              status: HangarPlanVehicleStatusEnum.PENDING,
            },
          ],
        },
      },
    });

    // Both stay above the finished route, the undecided one first.
    expect(rowTests(wrapper)).toEqual([
      "hangar-plan-flow-undecided",
      "hangar-plan-vehicle-review",
      "hangar-plan-vehicle-review",
      "hangar-plan-flow-purchase",
    ]);

    const [pending, change] = wrapper.findAll(
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
      ["vehicle-gladius", "keep"],
      ["vehicle-gladius", "change"],
      ["vehicle-cutlass", "pending"],
    ]);
    expect(opened(wrapper, "end")).toEqual([
      [
        {
          startName: "Gladius",
          startModel: model("Gladius"),
          vehicleId: "vehicle-gladius",
        },
      ],
    ]);
  });

  it("opens the route of a buy-back bought as it is, for its token", async () => {
    const [explorer, ...rest] = plan.slots;
    const [candidate] = explorer.candidates;
    const buyback = {
      ...candidate.acquisitions[0],
      startKind: HangarPlanStartKindEnum.BUYBACK,
    };
    const wrapper = await mountWithDefaults(Component, {
      props: {
        comparison,
        plan: {
          ...plan,
          slots: [
            {
              ...explorer,
              candidates: [{ ...candidate, acquisitions: [buyback] }],
            },
            ...rest,
          ],
        },
      },
    });

    await wrapper
      .find('[data-test="hangar-plan-flow-purchase"]')
      .find('[data-test="hangar-plan-flow-route"]')
      .trigger("click");

    expect(opened(wrapper, "route")).toHaveLength(1);
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

    const [[start]] = opened(wrapper, "start") as [
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

    const [[end]] = opened(wrapper, "end") as [
      [{ acquisition: { id: string }; slot: HangarPlanSlot }],
    ];
    expect([end.acquisition.id, end.slot.id]).toEqual(["bought", "Explorer"]);
  });

  it("plans the route from the middle once start and end differ", async () => {
    const cutlass = { ...model("Cutlass Black"), pledgePrice: 90 };
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
              pledgeShips: [],
              pledgeItems: [],
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

    const [[candidate, acquisition]] = opened(wrapper, "route") as [
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
    const open = wrapper.find('[data-test="hangar-plan-flow-open"]');
    await open.find('[data-test="hangar-plan-flow-pick"]').trigger("click");
    // Named, removed and given filters before it has a ship.
    await open
      .find('[data-test="hangar-plan-flow-slot-edit"]')
      .trigger("click");

    const [[start]] = opened(wrapper, "start") as [
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
    // A unit without a start has no route to plan yet: its middle asks for
    // the start as well.
    expect(opened(wrapper, "route")).toBeUndefined();
    expect(opened(wrapper, "start")).toHaveLength(2);
    expect(opened(wrapper, "slot")).toEqual([[short], [empty]]);
    expect(wrapper.emitted("editSlot")).toEqual([[empty]]);
  });

  it("prices a slot's units without a start, outside the total", async () => {
    const [explorer, ...rest] = plan.slots;
    const props = {
      plan: { ...plan, slots: [{ ...explorer, quantity: 2 }, ...rest] },
      comparison: {
        ...comparison,
        gaps: [
          { slotId: "Explorer", label: "Explorer", model: carrack, count: 1 },
        ],
      },
    };
    const summary = (storeCost: number | null, storeCostMin = storeCost) => ({
      totals: {} as HangarPlanSummary["totals"],
      issues: [],
      slots: [
        {
          slotId: "Explorer",
          state: HangarPlanSlotStateEnum.DECIDED,
          minCost: 600,
          maxCost: 600,
          storeCostMin,
          storeCost,
          unresolvedCount: 1,
          complete: false,
        },
      ],
    });
    const gapText = async (attrs: { summary?: HangarPlanSummary }) =>
      (await mountWithDefaults(Component, { props: { ...props, ...attrs } }))
        .find('[data-test="hangar-plan-gap"]')
        .text();

    expect(await gapText({ summary: summary(600) })).toContain("$600");
    expect(await gapText({ summary: summary(null) })).toContain("Unknown");
    expect(await gapText({ summary: summary(600, 150) })).toContain(
      "$150 – $600",
    );
    expect(await gapText({})).toContain("not in the total");
  });

  it("picks a start for an undecided slot, and opens its ships from the card", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { plan, comparison },
    });

    const undecided = wrapper.find('[data-test="hangar-plan-flow-undecided"]');
    // It still waits on a choice, so it reads as work and not as a purchase.
    expect(undecided.text()).toContain("Choose a ship");
    expect(undecided.find(".hangar-flow__action--gap").exists()).toBe(true);

    await undecided
      .find('[data-test="hangar-plan-flow-pick-start"]')
      .trigger("click");
    await undecided
      .find('[data-test="hangar-plan-flow-edit-slot"]')
      .trigger("click");
    await undecided
      .find('[data-test="hangar-plan-flow-route"]')
      .trigger("click");

    expect(opened(wrapper, "start")).toEqual([[{ slot: plan.slots[2] }]]);
    expect(opened(wrapper, "slot")).toEqual([[plan.slots[2]], [plan.slots[2]]]);
  });

  it("asks for another start where no upgrade leads to the slot's ship", async () => {
    const idris = {
      ...model("Idris-P"),
      pledgePrice: 1500,
      ccuInto: "none" as const,
      ccuOutOf: "none" as const,
    };
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

    expect(opened(wrapper, "route")).toBeUndefined();
    expect(
      (opened(wrapper, "start") as [[{ acquisition: { id: string } }]])[0][0]
        .acquisition.id,
    ).toEqual("bought");
  });

  it("only melts a ship RSI sells no upgrades for once it should change", async () => {
    const kraken = {
      ...model("Kraken"),
      pledgePrice: 1650,
      ccuInto: "none" as const,
      ccuOutOf: "none" as const,
    };
    const wrapper = await mountWithDefaults(Component, {
      props: {
        plan,
        comparison: {
          ...comparison,
          vehicles: [
            {
              vehicleId: "vehicle-kraken",
              pledgeShips: [],
              pledgeItems: [],
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
    ).toEqual([
      "hangar-plan-decide-keep",
      "hangar-plan-decide-melt",
      "hangar-plan-decide-pending",
    ]);
  });

  it("shows a start picked for an undecided slot as waiting for its ship", async () => {
    const cutlass = model("Cutlass Black");
    const prospector = model("Prospector");
    const [explorer, salvage, mining] = plan.slots;
    const undecided = {
      ...mining,
      candidates: [
        {
          ...salvage.candidates[0],
          id: "prospector",
          model: prospector,
          acquisitions: [
            {
              ...salvage.candidates[0].acquisitions[0],
              id: "waiting",
              sourceVehicleId: "vehicle-cutlass",
              startModel: cutlass,
              routeComplete: false,
            },
          ],
        },
        {
          ...salvage.candidates[0],
          id: "mole",
          model: model("MOLE"),
          acquisitions: [],
        },
      ],
    };
    const wrapper = await mountWithDefaults(Component, {
      props: {
        plan: { ...plan, slots: [explorer, salvage, undecided] },
        comparison: {
          ...comparison,
          vehicles: [
            {
              vehicleId: "vehicle-cutlass",
              pledgeShips: [],
              pledgeItems: [],
              model: cutlass,
              status: HangarPlanVehicleStatusEnum.UNROUTED,
            },
          ],
        },
      },
    });

    const row = wrapper.find('[data-test="hangar-plan-vehicle-waiting"]');
    expect(row.text()).toContain("Cutlass Black");
    expect(row.text()).toContain("Choose a ship");
    expect(row.text()).toContain("Prospector / MOLE");
    // Its one unit has a start, so no row asks for one any more.
    expect(
      wrapper.find('[data-test="hangar-plan-flow-undecided"]').exists(),
    ).toBe(false);

    await row.find('[data-test="hangar-plan-flow-route"]').trigger("click");
    await row
      .find('[data-test="hangar-plan-flow-pick-start"]')
      .trigger("click");

    expect(opened(wrapper, "slot")).toEqual([[undecided]]);
    const [[start]] = opened(wrapper, "start") as [
      [{ acquisition: { id: string } }],
    ];
    expect(start.acquisition.id).toBe("waiting");
  });
  describe("a slot with no ship yet", () => {
    const openSlot = (attrs: Partial<HangarPlanSlot> = {}): HangarPlanSlot => ({
      id: "open",
      label: "Fighter",
      quantity: 1,
      position: 0,
      state: HangarPlanSlotStateEnum.OPEN,
      filters: {},
      candidates: [],
      starts: [],
      ...attrs,
    });

    const mountOpen = (slot: HangarPlanSlot, vehicles: unknown[] = []) =>
      mountWithDefaults(Component, {
        props: {
          plan: { ...plan, slots: [slot] } as HangarPlan,
          comparison: {
            ...comparison,
            vehicles,
          } as HangarPlanComparison,
        },
      });

    const hull = { id: "hull", name: "Hull A", slug: "hull-a", onSale: true };

    it("shows a start it holds, and still lets ships be added", async () => {
      const start = {
        id: "start",
        startKind: "buyback",
        startModel: hull,
        sourceMissing: false,
      };
      const slot = openSlot({ starts: [start] as HangarPlanSlot["starts"] });
      const wrapper = await mountOpen(slot);

      const row = wrapper.find('[data-test="hangar-plan-flow-held"]');
      expect(row.text()).toContain("Hull A");
      expect(wrapper.find('[data-test="hangar-plan-flow-open"]').exists()).toBe(
        false,
      );

      await row
        .find('[data-test="hangar-plan-flow-pick-start"]')
        .trigger("click");
      await row.find('[data-test="hangar-plan-flow-pick"]').trigger("click");

      expect(opened(wrapper, "start")).toEqual([
        [{ slot, acquisition: start }],
      ]);
      expect(opened(wrapper, "slot")).toEqual([[slot]]);
    });

    it("names a ship to buy by how it is got, and keeps a row for the unit left", async () => {
      const slot = openSlot({
        quantity: 2,
        starts: [
          {
            id: "start",
            startKind: "store",
            startModel: null,
            sourceMissing: false,
          },
        ] as HangarPlanSlot["starts"],
      });
      const wrapper = await mountOpen(slot);

      expect(
        wrapper.find('[data-test="hangar-plan-flow-held"]').text(),
      ).toContain("Store purchase");
      expect(wrapper.find('[data-test="hangar-plan-flow-open"]').exists()).toBe(
        true,
      );
    });

    it("shows a hangar ship it holds on the ship's own row", async () => {
      const slot = openSlot({
        starts: [
          {
            id: "start",
            startKind: "owned",
            sourceVehicleId: "vehicle",
            startModel: hull,
            sourceMissing: false,
          },
        ] as HangarPlanSlot["starts"],
      });
      const wrapper = await mountOpen(slot, [
        {
          vehicleId: "vehicle",
          model: hull,
          status: HangarPlanVehicleStatusEnum.UNROUTED,
        },
      ]);

      expect(
        wrapper.find('[data-test="hangar-plan-vehicle-held"]').exists(),
      ).toBe(true);
      expect(wrapper.find('[data-test="hangar-plan-flow-held"]').exists()).toBe(
        false,
      );
    });

    it("edits and removes the slot from its row, with no modal in between", async () => {
      const slot = openSlot();
      const wrapper = await mountOpen(slot);
      const row = wrapper.find('[data-test="hangar-plan-flow-open"]');

      await row
        .find('[data-test="hangar-plan-flow-slot-edit"]')
        .trigger("click");

      expect(wrapper.emitted("editSlot")).toEqual([[slot]]);
      expect(
        row.find('[data-test="hangar-plan-flow-slot-remove"]').exists(),
      ).toBe(true);
    });
  });

  describe("a start whose hangar ship is gone", () => {
    const hull = { id: "hull", name: "Hull A", slug: "hull-a", onSale: true };
    const lost = {
      id: "lost",
      startKind: "owned",
      sourceVehicleId: "gone",
      startModel: hull,
      sourceMissing: true,
    };

    it("keeps a row for a slot holding it, to fix or remove", async () => {
      const held = slot("held", HangarPlanSlotStateEnum.OPEN, {
        starts: [lost] as HangarPlanSlot["starts"],
      });
      const wrapper = await mountWithDefaults(Component, {
        props: {
          plan: { ...plan, slots: [held] },
          comparison: { ...comparison, vehicles: [] },
        },
      });

      const row = wrapper.find('[data-test="hangar-plan-flow-held"]');
      expect(row.text()).toContain("no longer in your hangar");
      expect(
        row.find('[data-test="hangar-plan-flow-slot-remove"]').exists(),
      ).toBe(true);
    });

    it("does not call a ship gone that the plan merely no longer lists", async () => {
      const held = slot("held", HangarPlanSlotStateEnum.OPEN, {
        starts: [{ ...lost, sourceMissing: false }] as HangarPlanSlot["starts"],
      });
      const wrapper = await mountWithDefaults(Component, {
        props: {
          plan: { ...plan, slots: [held] },
          comparison: { ...comparison, vehicles: [] },
        },
      });

      const row = wrapper.find('[data-test="hangar-plan-flow-held"]');
      expect(row.text()).toContain("Kept from hangar");
      expect(row.text()).not.toContain("no longer in your hangar");
    });

    it("keeps a row for a route that still starts from it", async () => {
      const routed = slot("routed", HangarPlanSlotStateEnum.DECIDED, {
        candidates: [
          {
            id: "candidate",
            position: 0,
            model: carrack,
            modelModuleIds: [],
            modelUpgradeIds: [],
            matchesFilters: true,
            acquisitions: [
              {
                ...lost,
                routeComplete: false,
                usesBuybackToken: false,
                steps: [],
              },
            ],
          },
        ] as unknown as HangarPlanSlot["candidates"],
      });
      const wrapper = await mountWithDefaults(Component, {
        props: {
          plan: { ...plan, slots: [routed] },
          comparison: { ...comparison, vehicles: [] },
        },
      });

      expect(wrapper.text()).toContain("no longer in your hangar");
    });
  });

  describe("how a hangar ship was pledged", () => {
    const hull = { id: "hull", name: "Hull A", slug: "hull-a", onSale: true };

    const note = async (attrs: Record<string, unknown>) => {
      const wrapper = await mountWithDefaults(Component, {
        props: {
          plan: { ...plan, slots: [] } as HangarPlan,
          comparison: {
            ...comparison,
            vehicles: [
              {
                vehicleId: "vehicle",
                model: hull,
                status: HangarPlanVehicleStatusEnum.PENDING,
                ...attrs,
              },
            ],
          } as HangarPlanComparison,
        },
      });

      const pledge = wrapper.find('[data-test="hangar-plan-flow-pledge"]');
      return pledge.exists() ? pledge.text() : undefined;
    };

    it("says a ship is standalone", async () => {
      expect(await note({ standalone: true })).toBe("Standalone");
    });

    it("names the package a ship came in", async () => {
      expect(
        await note({
          standalone: false,
          pledgeName: "Package - Praetorian Pack",
        }),
      ).toBe("in Package - Praetorian Pack");
    });

    it("says nothing where the hangar sync never saw the pledge", async () => {
      expect(await note({ standalone: null })).toBeUndefined();
    });
  });

  describe("a ship RSI says does not melt", () => {
    const hull = { id: "hull", name: "Hull A", slug: "hull-a", onSale: true };

    const row = async (attrs: Record<string, unknown>) => {
      const wrapper = await mountWithDefaults(Component, {
        props: {
          plan: { ...plan, slots: [] } as HangarPlan,
          comparison: {
            ...comparison,
            vehicles: [
              {
                vehicleId: "vehicle",
                model: hull,
                status: HangarPlanVehicleStatusEnum.PENDING,
                pledgeShips: [],
                pledgeItems: [],
                ...attrs,
              },
            ],
          } as unknown as HangarPlanComparison,
        },
      });

      return wrapper;
    };

    const melts = '[data-test="hangar-plan-decide-melt"]';

    it("keeps the melt there but disabled, and says why", async () => {
      const wrapper = await row({ meltable: false });

      expect(wrapper.find(melts).attributes("disabled")).toBeDefined();
      expect(
        wrapper.find('[data-test="hangar-plan-decide-keep"]').exists(),
      ).toBe(true);

      expect(wrapper.find(melts).text()).toBe("Can't be melted");

      await wrapper.find(melts).trigger("click");
      expect(wrapper.emitted("decide")).toBeUndefined();
    });

    it("leaves the melt enabled where the sync never read the pledge", async () => {
      for (const meltable of [null, true]) {
        const wrapper = await row({ meltable });

        expect(wrapper.find(melts).attributes("disabled")).toBeUndefined();
        expect(wrapper.find(melts).text()).not.toContain("Can't be melted");
      }
    });

    it("says it can only be kept where no upgrade leads out of it either", async () => {
      const wrapper = await row({
        meltable: false,
        status: HangarPlanVehicleStatusEnum.CHANGE,
        model: { ...hull, ccuOutOf: "none" },
      });

      expect(wrapper.text()).toContain("it can only be kept");
      expect(wrapper.find(melts).attributes("disabled")).toBeDefined();
    });
  });

  it("opens the panel with every side the row has, and lights the row", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { plan, comparison },
    });

    await wrapper
      .find('[data-test="hangar-plan-flow-purchase"]')
      .find('[data-test="hangar-plan-flow-pick-start"]')
      .trigger("click");

    const [[target]] = wrapper.emitted("open") as [[HangarFlowTarget]];
    expect(target.tab).toBe("start");
    expect(target.start).toBeDefined();
    expect(target.end).toBeDefined();

    await wrapper.setProps({ activeKey: target.key });

    expect(
      wrapper
        .findAll(".hangar-flow__row--active")
        .map((row) => row.attributes("aria-current")),
    ).toEqual(["true"]);
  });
});
