import { afterEach, describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  BuybackPledgeKindEnum,
  HangarPlanStartKindEnum,
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
  useCreateHangarPlanAcquisition: () => ({ mutateAsync: vi.fn() }),
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

const mount = () =>
  mountWithDefaults(Component, {
    props: { planId: "plan", candidate },
  });

const rows = (wrapper: Awaited<ReturnType<typeof mount>>, list: string) =>
  wrapper.findAll(
    `[data-test="pick-list-${list}"] [data-test="pick-list-row"]`,
  );

describe("Hangar/Planner/RouteModal", () => {
  afterEach(() => {
    loading.value = false;
  });

  it("holds the start list open with placeholders while it loads", async () => {
    loading.value = true;
    const wrapper = await mount();

    expect(wrapper.find('[data-test="pick-list-loading"]').exists()).toBe(true);
    expect(wrapper.text()).not.toContain("No ship in your hangar");
  });

  it("offers no start that costs as much as the ship or more", async () => {
    const wrapper = await mount();

    const names = rows(wrapper, "sourceVehicleId").map((row) => row.text());
    expect(names).toHaveLength(2);
    expect(names.join(" ")).not.toContain("Hammerhead");
    expect(names.join(" ")).not.toContain("Freelancer MAX");
  });

  it("lists store ships below the target, the target itself on top", async () => {
    const wrapper = await mount();

    await wrapper
      .find('[data-test="hangar-plan-route-start-store"]')
      .trigger("click");

    // The store start defaults to the target, so the list opens folded on it.
    expect(
      wrapper.find('[data-test="pick-list-chosen-startModelId"]').text(),
    ).toContain("Carrack");
    await wrapper.find('[data-test="pick-list-change"]').trigger("click");

    const names = rows(wrapper, "startModelId").map((row) => row.text());
    expect(names[0]).toContain("Carrack");
    expect(names.join(" ")).not.toContain("Hammerhead");
    expect(names.join(" ")).not.toContain("Freelancer MAX");
  });

  it("prices a store upgrade as the difference to the ship it starts from", async () => {
    const wrapper = await mount();

    await rows(wrapper, "sourceVehicleId")
      .find((row) => row.text().includes("Cutlass Black"))
      ?.trigger("click");
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

  it("offers only the upgrades that start from the picked ship", async () => {
    const wrapper = await mount();

    await rows(wrapper, "sourceVehicleId")
      .find((row) => row.text().includes("Cutlass Black"))
      ?.trigger("click");

    // The Cutlass is not the Carrack, so the next upgrade is asked for at once.

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

  it("starts a buy-back on the ship of the pledge the plan needs", async () => {
    const wrapper = await mount();

    await wrapper
      .find('[data-test="hangar-plan-route-start-buyback"]')
      .trigger("click");
    await rows(wrapper, "buybackPledgeId")[0].trigger("click");

    const preview = wrapper.find('[data-test="hangar-plan-route-preview"]');
    expect(preview.text()).toContain("Buy-back");
    expect(preview.text()).toContain("The route ends on the Carrack.");
  });

  it("lists hangar ships cheapest first, or as the user sorts them", async () => {
    const wrapper = await mount();

    const titles = () =>
      rows(wrapper, "sourceVehicleId").map((row) =>
        row.find(".pick-list__title").text(),
      );
    expect(titles()).toEqual(["Aurora MR", "Cutlass Black"]);

    await wrapper
      .find('[data-test="pick-list-sort-sourceVehicleId"] button')
      .trigger("click");
    expect(titles()).toEqual(["Cutlass Black", "Aurora MR"]);
  });

  it("shows the ship the route leads to before anything is picked", async () => {
    const wrapper = await mount();

    const preview = wrapper.find('[data-test="hangar-plan-route-preview"]');
    expect(preview.text()).toContain("Still to reach");
    expect(preview.text()).toContain("Carrack");
  });

  it("puts a hangar ship that is the target itself on top", async () => {
    resources.value.vehicles.push({
      id: "vehicle-carrack",
      model: carrack,
      pledgeShips: [],
      pledgeItems: [],
    });
    const wrapper = await mount();

    const titles = rows(wrapper, "sourceVehicleId").map((row) =>
      row.find(".pick-list__title").text(),
    );
    expect(titles[0]).toBe("Carrack");

    resources.value.vehicles.pop();
  });

  it("folds the start list to the pick until the user changes it", async () => {
    const wrapper = await mount();

    await rows(wrapper, "sourceVehicleId")[0].trigger("click");

    expect(rows(wrapper, "sourceVehicleId")).toHaveLength(0);
    const chosen = wrapper.find(
      '[data-test="pick-list-chosen-sourceVehicleId"]',
    );
    expect(chosen.text()).toContain("Aurora MR");

    await chosen.find('[data-test="pick-list-change"]').trigger("click");
    expect(rows(wrapper, "sourceVehicleId")).toHaveLength(2);
  });

  it("builds a route from the target back to a ship in the hangar", async () => {
    const wrapper = await mount();

    await wrapper
      .find('[data-test="hangar-plan-route-direction-reverse"]')
      .trigger("click");

    // The first card opens by itself, asking for the upgrade into the Carrack,
    // and names each candidate by the ship it starts from.
    const upgrades = rows(wrapper, "backSteps.0.upgrade");
    expect(upgrades).toHaveLength(1);
    expect(upgrades[0].find(".pick-list__title").text()).toBe("Cutlass Black");
    expect(upgrades[0].text()).toContain("In your hangar");
    await upgrades[0].trigger("click");

    expect(
      wrapper.find('[data-test="hangar-plan-route-next"]').text(),
    ).toContain("The route now starts as the Cutlass Black.");

    // The next upgrade goes on top: it comes earlier in the route.
    await wrapper
      .find('[data-test="hangar-plan-route-next"] button')
      .trigger("click");
    const cards = wrapper.findAll('[data-test="hangar-plan-route-back-step"]');
    expect(cards).toHaveLength(2);
    expect(cards[0].text()).toContain("Upgrade into the Cutlass Black");
    expect(cards[1].text()).toContain("Upgrade into the Carrack");
    // Dropping it again leaves the route starting on the Cutlass.
    await wrapper
      .findAll('[data-test="hangar-plan-route-back-step"]')[0]
      .find('button[aria-label="Remove upgrade"]')
      .trigger("click");

    const starts = rows(wrapper, "sourceVehicleId");
    expect(starts.map((row) => row.text()).join(" ")).toContain(
      "Cutlass Black",
    );
    expect(starts).toHaveLength(1);
    await starts[0].trigger("click");

    const preview = wrapper.find('[data-test="hangar-plan-route-preview"]');
    expect(preview.text()).toContain("The route ends on the Carrack.");
  });

  it("opens a saved route in the same form, with its start picked", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        planId: "plan",
        candidate,
        acquisition: {
          id: "route",
          startKind: HangarPlanStartKindEnum.OWNED,
          sourceVehicleId: "vehicle-cutlass",
          startModel: cutlass,
          price: 0,
          sourceMissing: false,
          usesBuybackToken: false,
          steps: [],
        },
      },
    });

    expect(
      wrapper.find('[data-test="hangar-plan-route-start-store"]').exists(),
    ).toBe(true);
    expect(
      wrapper.find('[data-test="pick-list-chosen-sourceVehicleId"]').text(),
    ).toContain("Cutlass Black");
  });

  it("keeps the upgrade that reaches the ship", async () => {
    const wrapper = await mount();

    await rows(wrapper, "sourceVehicleId")
      .find((row) => row.text().includes("Cutlass Black"))
      ?.trigger("click");

    const remove = wrapper
      .find('[data-test="hangar-plan-route-step"]')
      .find('button[aria-label="Remove upgrade"]');
    expect(remove.attributes("disabled")).toBeDefined();
  });

  it("offers no in-game start once an upgrade is picked", async () => {
    const wrapper = await mount();
    const ingame = () =>
      wrapper.find('[data-test="hangar-plan-route-start-ingame"]');

    await rows(wrapper, "sourceVehicleId")
      .find((row) => row.text().includes("Cutlass Black"))
      ?.trigger("click");
    expect(ingame().attributes("disabled")).toBeUndefined();

    await rows(wrapper, "steps.0.upgrade")[0].trigger("click");
    expect(ingame().attributes("disabled")).toBeDefined();
  });

  it("takes no upgrades for a ship bought in game", async () => {
    const wrapper = await mount();

    await wrapper
      .find('[data-test="hangar-plan-route-start-ingame"]')
      .trigger("click");

    expect(wrapper.find('[data-test="pick-list-upgrades"]').exists()).toBe(
      false,
    );
    expect(
      wrapper.find('[data-test="hangar-plan-route-preview"]').text(),
    ).toContain("The route ends on the Carrack.");
  });

  it("offers to spend a buy-back token on a buy-back start", async () => {
    const wrapper = await mount();

    expect(
      wrapper.find('[data-test="hangar-plan-route-start-token"]').exists(),
    ).toBe(false);

    await wrapper
      .find('[data-test="hangar-plan-route-start-buyback"]')
      .trigger("click");

    expect(
      wrapper.find('[data-test="hangar-plan-route-start-token"]').exists(),
    ).toBe(true);
  });

  it("adds VAT to a buy-back paid without a token", async () => {
    const wrapper = await mount();

    await wrapper
      .find('[data-test="hangar-plan-route-start-buyback"]')
      .trigger("click");
    await rows(wrapper, "buybackPledgeId")
      .find((row) => row.text().includes("Standalone Ship - Carrack"))
      ?.trigger("click");

    const payment = wrapper.find('[data-test="hangar-plan-route-payment"]');
    expect(payment.text()).toContain("Store credit$0");
    expect(payment.text()).toContain("New money$600");
    expect(payment.text()).toContain("VAT (19%)$114");
    expect(payment.text()).toContain("New money with VAT$714");
  });

  it("narrows the buy-backs to those with lifetime insurance", async () => {
    const wrapper = await mount();

    await wrapper
      .find('[data-test="hangar-plan-route-start-buyback"]')
      .trigger("click");
    expect(rows(wrapper, "buybackPledgeId")).toHaveLength(2);

    await wrapper
      .find('[data-test="hangar-plan-route-filter-lti"] button')
      .trigger("click");

    const listed = rows(wrapper, "buybackPledgeId");
    expect(listed).toHaveLength(1);
    expect(listed[0].text()).toContain("Standalone Ship - Carrack");
    expect(listed[0].text()).toContain("LTI");
  });
});
