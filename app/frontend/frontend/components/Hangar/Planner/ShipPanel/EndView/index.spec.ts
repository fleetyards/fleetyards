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
  starts: [],
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

const pairEnd = vi.hoisted(() => vi.fn(() => Promise.resolve(true)));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useHangarPlan: () => ({ data: plan }),
  useHangarPlanResources: () => ({ data: resources, isLoading: ref(false) }),
}));

vi.mock("@/frontend/composables/useHangarPlanPairing", () => ({
  useHangarPlanPairing: () => ({ pairing: ref(false), pairEnd }),
}));

type Wrapper = Awaited<ReturnType<typeof mountWithDefaults>>;

const rows = (wrapper: Wrapper) =>
  wrapper.findAll('[data-test="ship-list-row"]');

const titles = (wrapper: Wrapper) =>
  rows(wrapper).map((row) => row.find(".ship-list__title").text());

const sectionOf = (wrapper: Wrapper, key: string) =>
  wrapper
    .find(`[data-test="ship-list-group-${key}"]`)
    .findAll('[data-test="ship-list-row"]')
    .map((row) => row.find(".ship-list__title").text());

const mount = () =>
  mountWithDefaults(Component, {
    props: {
      planId: "plan",
      startName: "Scorpius",
      startModel: scorpius,
      vehicleId: "vehicle-scorpius",
    },
  });

describe("Hangar/Planner/ShipPanel/EndView", () => {
  it("offers the plan's slots and any store ship the start upgrades into", async () => {
    const wrapper = await mount();

    // Not the Aurora, which is cheaper, nor the Idris, which takes no
    // upgrades; the Carrack once, as the slot the plan already has.
    expect(titles(wrapper)).toEqual([
      "Same ship, kept as it is",
      "Carrack",
      "Hammerhead",
    ]);
    expect(sectionOf(wrapper, "keep")).toEqual(["Same ship, kept as it is"]);
    expect(sectionOf(wrapper, "plan")).toEqual(["Carrack"]);
    expect(sectionOf(wrapper, "store")).toEqual(["Hammerhead"]);
  });

  it("prices each end by the upgrade from the start", async () => {
    const wrapper = await mount();

    const carrackRow = rows(wrapper).find((row) =>
      row.text().includes("Carrack"),
    )!;
    expect(carrackRow.find(".ship-list__price strong").text()).toBe("$360");
  });

  it("shows a ship's upgrade before ending the route on it", async () => {
    const wrapper = await mount();

    await rows(wrapper)
      .find((row) => row.text().includes("Hammerhead"))!
      .trigger("click");

    expect(wrapper.find('[data-test="ship-panel-upgrade"]').text()).toContain(
      "Scorpius to Hammerhead",
    );

    await wrapper.find('[data-test="ship-detail-commit"]').trigger("click");
    await flushPromises();

    expect(pairEnd).toHaveBeenLastCalledWith(
      { kind: "model", modelId: "Hammerhead", name: "Hammerhead" },
      { vehicleId: "vehicle-scorpius", acquisition: undefined },
    );
    expect(wrapper.emitted("done")).toHaveLength(1);
  });

  it("ends the route on a slot of the plan with a double click", async () => {
    const wrapper = await mount();

    await rows(wrapper)
      .find((row) => row.text().includes("Carrack"))!
      .trigger("dblclick");
    await flushPromises();

    expect(pairEnd).toHaveBeenLastCalledWith(
      {
        kind: "candidate",
        candidate: expect.objectContaining({ id: "candidate-Carrack" }),
      },
      { vehicleId: "vehicle-scorpius", acquisition: undefined },
    );
  });
});
