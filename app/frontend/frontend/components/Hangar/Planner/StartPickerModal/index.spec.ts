import { flushPromises } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  BuybackPledgeKindEnum,
  HangarPlanSlotStateEnum,
  HangarPlanVehicleStatusEnum,
  type HangarPlanBuybackResource,
  type HangarPlanCandidate,
  type HangarPlanComparison,
  type HangarPlanModel,
  type HangarPlanResources,
  type HangarPlanSlot,
  type HangarPlanVehicleResource,
} from "@/services/fyApi";
import Component from "./index.vue";

const model = (
  name: string,
  pledgePrice = 100,
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

const cutlass = model("Cutlass Black", 110);
const prospector = model("Prospector", 155);
const mole = model("MOLE", 315);
const idris = model("Idris-P", 1500, false);
const vulture = model("Vulture", 175);
const aurora = model("Aurora MR", 30);

const buyback = (
  id: string,
  attrs: Partial<HangarPlanBuybackResource> = {},
): HangarPlanBuybackResource => ({
  id,
  name: "Standalone Ship - Aurora MR",
  kind: BuybackPledgeKindEnum.SHIP,
  price: 30,
  used: false,
  lifetimeInsurance: true,
  insuranceKnown: true,
  models: [aurora],
  ...attrs,
});

const vehicle = (
  id: string,
  shipModel: HangarPlanModel,
): HangarPlanVehicleResource => ({
  id,
  model: shipModel,
  pledgeShips: [],
  pledgeItems: [],
});

const resources = ref<HangarPlanResources>({
  vehicles: [
    vehicle("vehicle-cutlass", cutlass),
    vehicle("vehicle-prospector", prospector),
    vehicle("vehicle-idris", idris),
    vehicle("vehicle-vulture", vulture),
  ],
  upgrades: [],
  storeModels: [],
  buybacks: [
    buyback("buyback-aurora"),
    buyback("buyback-used", { name: "Used - Aurora MR", used: true }),
    buyback("buyback-upgrade", {
      name: "Upgrade - Aurora MR to Prospector",
      kind: BuybackPledgeKindEnum.UPGRADE,
    }),
  ],
});

const comparison = ref({
  vehicles: [
    {
      vehicleId: "vehicle-cutlass",
      model: cutlass,
      status: HangarPlanVehicleStatusEnum.CHANGE,
    },
    {
      vehicleId: "vehicle-prospector",
      model: prospector,
      status: HangarPlanVehicleStatusEnum.PENDING,
    },
    {
      vehicleId: "vehicle-vulture",
      model: vulture,
      status: HangarPlanVehicleStatusEnum.PENDING,
    },
    {
      vehicleId: "vehicle-idris",
      model: idris,
      status: HangarPlanVehicleStatusEnum.UNASSIGNED,
    },
  ],
} as unknown as HangarPlanComparison);

const pairStart = vi.fn((..._args: unknown[]) => Promise.resolve(true));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useHangarPlan: () => ({ data: ref(undefined) }),
  useHangarPlanComparison: () => ({ data: comparison }),
  useHangarPlanResources: () => ({ data: resources, isLoading: ref(false) }),
}));

vi.mock("@/frontend/composables/useHangarPlanPairing", () => ({
  useHangarPlanPairing: () => ({
    pairing: ref(false),
    pairStart,
    pairEnd: vi.fn(),
  }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit: vi.fn(), on: vi.fn(), off: vi.fn() }),
}));

const candidate = (shipModel: HangarPlanModel): HangarPlanCandidate => ({
  id: `candidate-${shipModel.id}`,
  position: 0,
  model: shipModel,
  modelModuleIds: [],
  modelUpgradeIds: [],
  matchesFilters: true,
  acquisitions: [],
});

const slot = (candidates: HangarPlanCandidate[]): HangarPlanSlot => ({
  id: "mining",
  label: "Solo Miner",
  quantity: 1,
  position: 0,
  state:
    candidates.length > 1
      ? HangarPlanSlotStateEnum.UNDECIDED
      : HangarPlanSlotStateEnum.DECIDED,
  filters: {},
  candidates,
});

const titles = (wrapper: Awaited<ReturnType<typeof mountWithDefaults>>) =>
  wrapper
    .findAll('[data-test="pick-list-row"]')
    .map((row) => row.find(".pick-list__title").text());

const use = async (
  wrapper: Awaited<ReturnType<typeof mountWithDefaults>>,
  title: string,
) => {
  await wrapper
    .findAll('[data-test="pick-list-row"]')
    .find((row) => row.text().includes(title))!
    .find('[data-test="pick-list-use"]')
    .trigger("click");
  await flushPromises();
};

describe("Hangar/Planner/StartPickerModal", () => {
  it("narrows the hangar ships to those marked to change", async () => {
    const mining = candidate(prospector);
    const wrapper = await mountWithDefaults(Component, {
      props: { planId: "plan", slot: slot([mining]), candidate: mining },
    });

    // No upgrade leads out of the Idris, and the Vulture is no cheaper than
    // a Prospector, so neither is a start for one.
    expect(titles(wrapper)).toEqual([
      "Buy new on the store",
      "Prospector",
      "Standalone Ship - Aurora MR",
      "Cutlass Black",
    ]);

    await wrapper
      .find('[data-test="hangar-plan-start-filter-change"] .chip__toggle')
      .trigger("click");

    expect(titles(wrapper)).toEqual(["Cutlass Black"]);

    await use(wrapper, "Cutlass Black");

    expect(pairStart).toHaveBeenLastCalledWith(
      mining,
      { kind: "owned", vehicleId: "vehicle-cutlass" },
      undefined,
    );
  });

  it("starts from a buy-back, narrowed to the buy-backs", async () => {
    const mining = candidate(prospector);
    const wrapper = await mountWithDefaults(Component, {
      props: { planId: "plan", slot: slot([mining]), candidate: mining },
    });

    await wrapper
      .find('[data-test="hangar-plan-start-source-buyback"] .chip__toggle')
      .trigger("click");

    expect(titles(wrapper)).toEqual(["Standalone Ship - Aurora MR"]);

    await use(wrapper, "Aurora MR");

    expect(pairStart).toHaveBeenLastCalledWith(
      mining,
      { kind: "buyback", pledgeId: "buyback-aurora", modelId: "Aurora MR" },
      undefined,
    );
  });

  it("keeps a start for an undecided slot without choosing its ship", async () => {
    const options = [candidate(prospector), candidate(mole)];
    const wrapper = await mountWithDefaults(Component, {
      props: { planId: "plan", slot: slot(options) },
    });

    // Anything that can become one of its ships, never an Idris RSI sells
    // no upgrades for; the Vulture at $175 can only become the MOLE.
    expect(titles(wrapper)).toEqual([
      "Buy new on the store",
      "Standalone Ship - Aurora MR",
      "Cutlass Black",
      "Prospector",
      "Vulture",
    ]);
    const vultureRow = wrapper
      .findAll('[data-test="pick-list-row"]')
      .find((row) => row.text().includes("Vulture"))!;
    expect(vultureRow.text()).toContain("Rules out Prospector");

    // Picking a start decides nothing: it waits on the ship it comes
    // closest to until the slot chooses.
    await use(wrapper, "Prospector");
    expect(pairStart).toHaveBeenLastCalledWith(
      options[0],
      { kind: "owned", vehicleId: "vehicle-prospector" },
      undefined,
    );

    await use(wrapper, "Vulture");
    expect(pairStart).toHaveBeenLastCalledWith(
      options[1],
      { kind: "owned", vehicleId: "vehicle-vulture" },
      undefined,
    );
  });
});
