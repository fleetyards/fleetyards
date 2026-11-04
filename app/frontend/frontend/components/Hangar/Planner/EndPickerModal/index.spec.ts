import { flushPromises } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  HangarPlanSlotStateEnum,
  type HangarPlan,
  type HangarPlanCandidate,
  type HangarPlanModel,
  type HangarPlanResources,
  type HangarPlanSlot,
} from "@/services/fyApi";
import Component from "./index.vue";

const model = (
  name: string,
  pledgePrice: number,
  upgradable = true,
): HangarPlanModel => ({
  id: name,
  name,
  slug: name.toLowerCase(),
  onSale: true,
  ccuInto: upgradable ? "on_sale" : "none",
  ccuOutOf: upgradable ? "known" : "none",
  pledgePrice,
});

const aurora = model("Aurora MR", 30);
const scorpius = model("Scorpius", 240);
const carrack = model("Carrack", 600);
const hammerhead = model("Hammerhead", 725);
const idris = model("Idris-P", 1900, false);

const candidate = (shipModel: HangarPlanModel): HangarPlanCandidate => ({
  id: `candidate-${shipModel.id}`,
  position: 0,
  model: shipModel,
  modelModuleIds: [],
  modelUpgradeIds: [],
  matchesFilters: true,
  acquisitions: [],
});

const slot = (id: string, shipModel: HangarPlanModel): HangarPlanSlot => ({
  id,
  label: id,
  quantity: 1,
  position: 0,
  state: HangarPlanSlotStateEnum.DECIDED,
  filters: {},
  candidates: [candidate(shipModel)],
});

const plan = ref({
  id: "plan",
  vehicleMarks: [],
  slots: [slot("Explorer", carrack)],
} as unknown as HangarPlan);

const resources = ref({
  vehicles: [],
  upgrades: [],
  buybacks: [],
  storeModels: [aurora, scorpius, carrack, hammerhead, idris],
} as HangarPlanResources);

const pairEnd = vi.fn((..._args: unknown[]) => Promise.resolve(true));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useHangarPlan: () => ({ data: plan }),
  useHangarPlanResources: () => ({ data: resources, isLoading: ref(false) }),
}));

vi.mock("@/frontend/composables/useHangarPlanPairing", () => ({
  useHangarPlanPairing: () => ({ pairing: ref(false), pairEnd }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit: vi.fn(), on: vi.fn(), off: vi.fn() }),
}));

const titles = (wrapper: Awaited<ReturnType<typeof mountWithDefaults>>) =>
  wrapper
    .findAll('[data-test="pick-list-row"]')
    .map((row) => row.find(".pick-list__title").text());

describe("Hangar/Planner/EndPickerModal", () => {
  it("offers the plan's slots and any ship the start can be upgraded into", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        planId: "plan",
        startName: "Scorpius",
        startModel: scorpius,
        vehicleId: "vehicle-scorpius",
      },
    });

    // Not the Aurora, which is cheaper, nor the Idris, which takes no
    // upgrades; the Carrack once, as the slot the plan already has.
    expect(titles(wrapper)).toEqual([
      "Same ship, kept as it is",
      "Carrack",
      "Hammerhead",
    ]);

    await wrapper
      .findAll('[data-test="pick-list-row"]')
      .find((row) => row.text().includes("Hammerhead"))!
      .trigger("click");
    await flushPromises();

    expect(pairEnd).toHaveBeenLastCalledWith(
      { kind: "model", modelId: "Hammerhead", name: "Hammerhead" },
      { vehicleId: "vehicle-scorpius", acquisition: undefined },
    );
  });
});
