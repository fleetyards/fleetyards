import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  HangarPlanModelChangeEnum,
  HangarPlanSlotStateEnum,
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
  ships: HangarPlanModel[],
): HangarPlanSlot => ({
  id,
  label: id,
  position: 0,
  state,
  filters: {},
  starts: [],
  candidates: ships.map((ship, position) => ({
    id: `${id}-${ship.id}`,
    position,
    model: ship,
    modelModuleIds: [],
    modelUpgradeIds: [],
    matchesFilters: true,
    acquisitions: [],
  })),
});

const crucible = model("Crucible");
const stingray = model("Stingray");
const odyssey = model("Odyssey");
const carrack = model("Carrack");

const comparison: HangarPlanComparison = {
  vehicles: [],
  models: [
    {
      model: crucible,
      leftCount: 0,
      rightCount: 1,
      change: HangarPlanModelChangeEnum.ADDED,
    },
    {
      model: stingray,
      leftCount: 1,
      rightCount: 1,
      change: HangarPlanModelChangeEnum.UNCHANGED,
    },
  ],
  gaps: [
    { slotId: "Hauler", label: "Hauler", model: crucible },
    { slotId: "Fighter", label: "Fighter", model: stingray },
  ],
  metrics: { live: metrics(), plan: metrics() },
};

const mount = (slots: HangarPlanSlot[] = []) =>
  mountWithDefaults(Component, { props: { comparison, slots } });

describe("ComparisonDetails", () => {
  it("brings in a slot without a route whose count the plan evens out", async () => {
    const wrapper = await mount();

    const diffs = wrapper.findAll('[data-test="hangar-plan-model-diff"]');
    const slots = wrapper.findAll('[data-test="hangar-plan-slot-diff"]');

    expect(diffs.map((row) => row.text())).toEqual([
      expect.stringContaining("Crucible"),
    ]);
    expect(slots).toHaveLength(1);
    expect(slots[0].text()).toContain("Stingray");
    expect(slots[0].text()).toContain("Fighter");
  });

  it("brings in an undecided slot with every ship it weighs", async () => {
    const wrapper = await mount([
      slot("Explorer", HangarPlanSlotStateEnum.UNDECIDED, [odyssey, carrack]),
      slot("Hauler", HangarPlanSlotStateEnum.DECIDED, [crucible]),
    ]);

    const texts = wrapper
      .findAll('[data-test="hangar-plan-slot-diff"]')
      .map((row) => row.text());

    expect(texts).toHaveLength(2);
    expect(texts[1]).toContain("Odyssey");
    expect(texts[1]).toContain("Carrack");
    expect(texts[1]).toContain("Explorer");
  });
});
