import { flushPromises } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  BuybackPledgeKindEnum,
  type HangarPlan,
  type HangarPlanAcquisition,
  HangarPlanSlotStateEnum,
  HangarPlanVehicleStatusEnum,
  NullableHangarPlanVehicleUseEnum,
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
const mustang = model("Mustang Alpha", 30);

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
    vehicle("vehicle-mustang", mustang),
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
      vehicleId: "vehicle-mustang",
      model: mustang,
      status: HangarPlanVehicleStatusEnum.KEPT,
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

const planData = ref<HangarPlan>();

const pairStart = vi.hoisted(() => vi.fn(() => Promise.resolve(true)));
const holdStart = vi.hoisted(() => vi.fn(() => Promise.resolve(true)));
const pairEnd = vi.hoisted(() => vi.fn(() => Promise.resolve(true)));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useHangarPlan: () => ({ data: planData }),
  useHangarPlanComparison: () => ({ data: comparison }),
  useHangarPlanResources: () => ({ data: resources, isLoading: ref(false) }),
}));

vi.mock("@/frontend/composables/useHangarPlanPairing", () => ({
  useHangarPlanPairing: () => ({
    pairing: ref(false),
    pairStart,
    holdStart,
    pairEnd,
  }),
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
  starts: [],
});

type Wrapper = Awaited<ReturnType<typeof mountWithDefaults>>;

const rows = (wrapper: Wrapper) =>
  wrapper.findAll('[data-test="ship-list-row"]');

const titles = (wrapper: Wrapper) =>
  rows(wrapper).map((row) => row.find(".ship-list__title").text());

const outRows = (wrapper: Wrapper) =>
  wrapper.findAll('[data-test="ship-list-out"]').map((row) => row.text());

const use = async (wrapper: Wrapper, title: string) => {
  await rows(wrapper)
    .find((row) => row.text().includes(title))!
    .trigger("click");
  await wrapper.find('[data-test="ship-detail-commit"]').trigger("click");
  await flushPromises();
};

describe("Hangar/Planner/ShipPanel/StartView", () => {
  it("groups the starts by where they come from, cheapest first", async () => {
    const mining = candidate(prospector);
    const wrapper = await mountWithDefaults(Component, {
      props: { planId: "plan", slot: slot([mining]), candidate: mining },
    });

    expect(titles(wrapper)).toEqual([
      "Earn in game",
      "Buy new on the store",
      "Prospector",
      "Cutlass Black",
      "Standalone Ship - Aurora MR",
    ]);

    await use(wrapper, "Cutlass Black");

    expect(pairStart).toHaveBeenLastCalledWith(
      mining,
      { kind: "owned", vehicleId: "vehicle-cutlass" },
      undefined,
    );
    expect(wrapper.emitted("done")).toHaveLength(1);
  });

  it("lists the ships that can't start the route, with why", async () => {
    const mining = candidate(prospector);
    const wrapper = await mountWithDefaults(Component, {
      props: { planId: "plan", slot: slot([mining]), candidate: mining },
    });

    const out = outRows(wrapper);
    expect(out).toHaveLength(4);
    expect(out.find((row) => row.includes("Idris-P"))).toContain(
      "No upgrade leads out of it",
    );
    expect(out.find((row) => row.includes("Vulture"))).toContain(
      "is not below the Prospector's",
    );
    expect(out.find((row) => row.includes("Mustang Alpha"))).toContain(
      "Kept as it is",
    );
    expect(out.find((row) => row.includes("Used - Aurora MR"))).toContain(
      "Already starts another route",
    );
  });

  it("starts from a buy-back, narrowed to the buy-backs", async () => {
    const mining = candidate(prospector);
    const wrapper = await mountWithDefaults(Component, {
      props: { planId: "plan", slot: slot([mining]), candidate: mining },
    });

    await wrapper
      .find('[data-test="ship-list-section-buyback"] .chip__toggle')
      .trigger("click");

    expect(titles(wrapper)).toEqual(["Standalone Ship - Aurora MR"]);

    await use(wrapper, "Aurora MR");

    expect(pairStart).toHaveBeenLastCalledWith(
      mining,
      { kind: "buyback", pledgeId: "buyback-aurora", modelId: "Aurora MR" },
      undefined,
    );
  });

  it("holds a start on a slot with no ship yet, whatever the ship can become", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { planId: "plan", slot: slot([]) },
    });

    // Even the Idris, which RSI sells no upgrades out of: it can stay itself.
    expect(titles(wrapper)).toEqual(
      expect.arrayContaining(["Vulture", "Idris-P", "Prospector"]),
    );

    pairStart.mockClear();
    await use(wrapper, "Vulture");

    expect(pairStart).not.toHaveBeenCalled();
    expect(holdStart).toHaveBeenLastCalledWith(
      expect.objectContaining({ id: "mining" }),
      { kind: "owned", vehicleId: "vehicle-vulture" },
      undefined,
    );
  });

  it("keeps a start for an undecided slot without choosing its ship", async () => {
    const options = [candidate(prospector), candidate(mole)];
    const wrapper = await mountWithDefaults(Component, {
      props: { planId: "plan", slot: slot(options) },
    });

    const vultureRow = rows(wrapper).find((row) =>
      row.text().includes("Vulture"),
    )!;
    expect(vultureRow.text()).toContain("Rules out Prospector");

    // Picking a start decides nothing: it waits on the ship it comes closest
    // to until the slot chooses.
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

  it("moves with the arrow keys and uses the start with Enter", async () => {
    const mining = candidate(prospector);
    const wrapper = await mountWithDefaults(Component, {
      props: { planId: "plan", slot: slot([mining]), candidate: mining },
    });

    const list = wrapper.find('[data-test="ship-list-start"]');
    // The first start is shown until another is picked.
    await list.trigger("keydown", { key: "ArrowDown" });
    await list.trigger("keydown", { key: "ArrowDown" });
    await rows(wrapper)
      .find(
        (row) => row.attributes("data-id") === "vehicle:vehicle-prospector",
      )!
      .trigger("keydown", { key: "Enter" });
    await flushPromises();

    expect(pairStart).toHaveBeenLastCalledWith(
      mining,
      { kind: "owned", vehicleId: "vehicle-prospector" },
      undefined,
    );
  });

  it("takes a start out of its slot", async () => {
    const mining = candidate(prospector);
    const acquisition = {
      id: "acquisition",
      sourceVehicleId: "vehicle-cutlass",
    } as unknown as HangarPlanAcquisition;
    const wrapper = await mountWithDefaults(Component, {
      props: {
        planId: "plan",
        slot: slot([mining]),
        candidate: mining,
        acquisition,
      },
    });

    await wrapper
      .find('[data-test="hangar-plan-start-remove"]')
      .trigger("click");
    await flushPromises();

    expect(pairEnd).toHaveBeenLastCalledWith(
      { kind: "remove" },
      { acquisition },
    );
    expect(wrapper.emitted("done")).toHaveLength(1);
  });

  it("does not use a start on Enter in the search field", async () => {
    const mining = candidate(prospector);
    const wrapper = await mountWithDefaults(Component, {
      props: { planId: "plan", slot: slot([mining]), candidate: mining },
    });
    pairStart.mockClear();

    await wrapper
      .find('[data-test="ship-list-start"] input')
      .trigger("keydown", { key: "Enter" });
    await flushPromises();

    expect(pairStart).not.toHaveBeenCalled();
  });

  it("offers the pledge of a ship the plan melts as a buy-back", async () => {
    const nomad = model("Nomad", 80);
    const melted = {
      ...vehicle("vehicle-nomad", nomad),
      usedBy: NullableHangarPlanVehicleUseEnum.MELT,
      meltValue: 75,
    };
    const before = resources.value;
    resources.value = { ...before, vehicles: [...before.vehicles, melted] };

    const mining = candidate(prospector);
    const wrapper = await mountWithDefaults(Component, {
      props: { planId: "plan", slot: slot([mining]), candidate: mining },
    });

    const row = wrapper
      .find('[data-test="ship-list-group-buyback"]')
      .findAll('[data-test="ship-list-row"]')
      .find((entry) => entry.text().includes("Nomad"))!;
    expect(row.text()).toContain("Bought back after melting");
    // Buying it back for what melting it credits, then upgrading to the
    // Prospector.
    expect(row.find(".ship-list__price strong").text()).toBe("$150");

    await use(wrapper, "Nomad");

    expect(pairStart).toHaveBeenLastCalledWith(
      mining,
      { kind: "melted", vehicleId: "vehicle-nomad" },
      undefined,
    );

    resources.value = before;
  });

  it("rules out the other ships of a melted pledge once one is bought back", async () => {
    const nomad = model("Nomad", 80);
    const avenger = model("Avenger Titan", 50);
    const melt = (id: string, ship: HangarPlanModel, sibling: string) => ({
      ...vehicle(id, ship),
      usedBy: NullableHangarPlanVehicleUseEnum.MELT,
      meltValue: 75,
      pledgeShips: [{ id: sibling, model: ship }],
    });
    const before = resources.value;
    resources.value = {
      ...before,
      vehicles: [
        ...before.vehicles,
        melt("vehicle-nomad", nomad, "vehicle-avenger"),
        melt("vehicle-avenger", avenger, "vehicle-nomad"),
      ],
    };
    planData.value = {
      melts: [],
      slots: [
        {
          starts: [],
          candidates: [
            {
              acquisitions: [
                {
                  id: "other",
                  startKind: "melted",
                  sourceVehicleId: "vehicle-nomad",
                },
              ],
            },
          ],
        },
      ],
    } as unknown as HangarPlan;

    const mining = candidate(prospector);
    const wrapper = await mountWithDefaults(Component, {
      props: { planId: "plan", slot: slot([mining]), candidate: mining },
    });

    const out = outRows(wrapper);
    expect(out.find((row) => row.includes("Avenger Titan"))).toContain(
      "Already starts another route",
    );

    resources.value = before;
    planData.value = undefined;
  });

  it("buys back an upgraded pledge as the ship it was first bought as", async () => {
    const ironclad = model("Ironclad Assault", 650);
    const starlancer = model("Starlancer MAX", 150);
    const melted = {
      ...vehicle("vehicle-ironclad", ironclad),
      usedBy: NullableHangarPlanVehicleUseEnum.MELT,
      meltValue: 465,
      baseModel: starlancer,
    };
    const before = resources.value;
    resources.value = { ...before, vehicles: [...before.vehicles, melted] };

    const mining = candidate(prospector);
    const wrapper = await mountWithDefaults(Component, {
      props: { planId: "plan", slot: slot([mining]), candidate: mining },
    });

    // As an Ironclad it could never become a Prospector; as the Starlancer
    // MAX its pledge comes back as, it can.
    const row = wrapper
      .find('[data-test="ship-list-group-buyback"]')
      .findAll('[data-test="ship-list-row"]')
      .find((entry) => entry.text().includes("Via melted Ironclad Assault"))!;
    expect(row.find(".ship-list__title").text()).toBe("Starlancer MAX");
    expect(row.find(".ship-list__price strong").text()).toBe("$155");

    resources.value = before;
  });
});
