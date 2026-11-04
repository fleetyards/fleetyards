import { afterEach, describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  BuybackPledgeKindEnum,
  HangarPlanStartKindEnum,
  type HangarPlanAcquisition,
  type HangarPlanCandidate,
  type HangarPlanModel,
  type HangarPlanResources,
} from "@/services/fyApi";
import Component from "./index.vue";

const model = (name: string, pledgePrice = 100): HangarPlanModel => ({
  id: name,
  name,
  slug: name.toLowerCase(),
  onSale: true,
  ccuInto: "on_sale",
  ccuOutOf: "known",
  pledgePrice,
});

const cutlass = model("Cutlass Black", 110);
const aurora = model("Aurora MR", 30);
const carrack = model("Carrack", 600);
const taurus = model("Constellation Taurus", 150);
const hammerhead = model("Hammerhead", 725);
const freelancer = model("Freelancer MAX", 600);

const loading = ref(false);

const resources = ref<HangarPlanResources>({
  vehicles: [
    { id: "vehicle-cutlass", model: cutlass, pledgeShips: [], pledgeItems: [] },
    { id: "vehicle-aurora", model: aurora, pledgeShips: [], pledgeItems: [] },
    {
      id: "vehicle-hammerhead",
      model: hammerhead,
      pledgeShips: [],
      pledgeItems: [],
    },
    {
      id: "vehicle-freelancer",
      model: freelancer,
      pledgeShips: [],
      pledgeItems: [],
    },
  ],
  upgrades: [
    {
      id: "ccu-cutlass",
      name: "Upgrade - Cutlass Black To Carrack",
      quantity: 1,
      usedCount: 0,
      fromModel: cutlass,
      toModel: carrack,
    },
    {
      id: "ccu-aurora",
      name: "Upgrade - Aurora MR To Constellation Taurus",
      quantity: 1,
      usedCount: 0,
      fromModel: aurora,
      toModel: taurus,
    },
  ],
  storeModels: [aurora, cutlass, taurus, carrack, freelancer, hammerhead],
  buybacks: [
    {
      id: "pledge-pack",
      name: "Explorer Pack",
      kind: BuybackPledgeKindEnum.PACKAGE,
      price: 700,
      used: false,
      lifetimeInsurance: false,
      insuranceKnown: false,
      models: [cutlass, carrack],
    },
    {
      id: "pledge-lti",
      name: "Standalone Ship - Carrack",
      kind: BuybackPledgeKindEnum.SHIP,
      price: 600,
      used: false,
      lifetimeInsurance: true,
      insuranceKnown: true,
      models: [carrack],
    },
  ],
});

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useHangarPlan: () => ({ data: ref({ vatRate: 19 }) }),
  useHangarPlanResources: () => ({ data: resources, isLoading: loading }),
  useUpdateHangarPlanAcquisition: () => ({ mutateAsync: vi.fn() }),
}));

vi.mock("@/frontend/composables/useHangarPlanCache", () => ({
  useHangarPlanCache: () => ({ updatePlan: vi.fn() }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit: vi.fn(), on: vi.fn(), off: vi.fn() }),
}));

const candidate: HangarPlanCandidate = {
  id: "candidate",
  position: 0,
  model: carrack,
  modelModuleIds: [],
  modelUpgradeIds: [],
  matchesFilters: true,
  acquisitions: [],
};

const pairing = (
  attrs: Partial<HangarPlanAcquisition> = {},
): HangarPlanAcquisition => ({
  id: "route",
  startKind: HangarPlanStartKindEnum.OWNED,
  sourceVehicleId: "vehicle-cutlass",
  startModel: cutlass,
  price: 0,
  routeComplete: false,
  sourceMissing: false,
  usesBuybackToken: false,
  steps: [],
  ...attrs,
});

const mount = (acquisition = pairing()) =>
  mountWithDefaults(Component, {
    props: { planId: "plan", candidate, acquisition },
  });

const rows = (wrapper: Awaited<ReturnType<typeof mount>>, list: string) =>
  wrapper.findAll(
    `[data-test="pick-list-${list}"] [data-test="pick-list-row"]`,
  );

describe("Hangar/Planner/RouteModal", () => {
  afterEach(() => {
    loading.value = false;
  });

  it("builds the chain from the start the row picked, which it does not change", async () => {
    const wrapper = await mount();

    const start = wrapper.find('[data-test="hangar-plan-route-ship-card"]');
    expect(start.text()).toContain("Cutlass Black");
    expect(start.text()).toContain("Kept from hangar");
    expect(
      wrapper.find('[data-test="hangar-plan-route-start-store"]').exists(),
    ).toBe(false);
    expect(
      wrapper
        .find('[data-test="hangar-plan-route-direction-reverse"]')
        .exists(),
    ).toBe(false);
  });

  it("prices a store upgrade as the difference to the ship it starts from", async () => {
    const wrapper = await mount();

    await wrapper
      .find('[data-test="hangar-plan-route-step-source-store"]')
      .trigger("click");

    const targets = rows(wrapper, "steps.0.toModelId").map((row) => row.text());
    expect(targets).toHaveLength(2);
    expect(targets[0]).toContain("Carrack");
    expect(targets[0]).toContain("$490");
    expect(targets[1]).toContain("Constellation Taurus");
    expect(targets[1]).toContain("$40");
  });

  it("offers only the upgrades that start from the start", async () => {
    const wrapper = await mount();

    // The Cutlass upgrade is in the RSI hangar, so the step starts there.
    const step = wrapper.find('[data-test="hangar-plan-route-step"]');
    expect(
      step
        .find('[data-test="hangar-plan-route-step-source-owned_ccu"]')
        .classes(),
    ).toContain("active");

    const upgrades = rows(wrapper, "steps.0.upgrade");
    expect(upgrades).toHaveLength(1);
    expect(upgrades[0].text()).toContain("Carrack");
    expect(upgrades[0].text()).toContain("1 left");

    await upgrades[0].trigger("click");

    const preview = wrapper.find('[data-test="hangar-plan-route-preview"]');
    expect(preview.text()).toContain("The route ends on the Carrack.");
    expect(
      wrapper
        .find('[data-test="hangar-plan-route-save"]')
        .attributes("disabled"),
    ).toBeUndefined();
  });

  it("keeps the upgrade that reaches the ship", async () => {
    const wrapper = await mount();

    const remove = wrapper
      .find('[data-test="hangar-plan-route-step"]')
      .find('button[aria-label="Remove upgrade"]');
    expect(remove.attributes("disabled")).toBeDefined();
  });

  it("offers to spend a buy-back token only on a buy-back start", async () => {
    const owned = await mount();
    expect(
      owned.find('[data-test="hangar-plan-route-start-token"]').exists(),
    ).toBe(false);

    const bought = await mount(
      pairing({
        startKind: HangarPlanStartKindEnum.BUYBACK,
        sourceVehicleId: null,
        buybackPledgeId: "pledge-lti",
        startModel: carrack,
      }),
    );
    expect(
      bought.find('[data-test="hangar-plan-route-start-token"]').exists(),
    ).toBe(true);
  });

  it("adds VAT to a buy-back paid without a token", async () => {
    const wrapper = await mount(
      pairing({
        startKind: HangarPlanStartKindEnum.BUYBACK,
        sourceVehicleId: null,
        buybackPledgeId: "pledge-lti",
        startModel: carrack,
      }),
    );

    const payment = wrapper.find('[data-test="hangar-plan-route-payment"]');
    expect(payment.text()).toContain("Store credit$0");
    expect(payment.text()).toContain("New money$600");
    expect(payment.text()).toContain("VAT (19%)$114");
    expect(payment.text()).toContain("New money with VAT$714");
  });
});
