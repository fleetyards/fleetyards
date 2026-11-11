import { describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  HangarPledgeItemKindEnum,
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
const carrack = model("Carrack", 600);
const aurora = model("Aurora MR", 30);

const resources = ref<HangarPlanResources>({
  vehicles: [
    {
      id: "vehicle-cutlass",
      model: cutlass,
      meltable: true,
      meltValue: 700,
      pledgeItemCount: 5,
      pledgeName: "Package - Explorer Pack",
      lifetimeInsurance: false,
      insuranceKnown: false,
      pledgeShips: [{ id: "vehicle-carrack", model: carrack }],
      pledgeItems: [
        {
          id: "paint",
          name: "Carrack - Ghoul Paint",
          kind: HangarPledgeItemKindEnum.PAINT,
          quantity: 2,
        },
      ],
    },
    {
      id: "vehicle-aurora",
      model: aurora,
      meltable: true,
      meltValue: 30,
      pledgeItemCount: 1,
      pledgeName: "Standalone Ship - Aurora MR",
      lifetimeInsurance: false,
      insuranceKnown: false,
      pledgeShips: [],
      pledgeItems: [],
    },
    {
      id: "vehicle-gift",
      model: model("Gifted Ship", 50),
      meltable: false,
      lifetimeInsurance: false,
      insuranceKnown: false,
      pledgeShips: [],
      pledgeItems: [],
    },
  ],
  upgrades: [],
  storeModels: [],
  buybacks: [],
});

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useHangarPlanResources: () => ({ data: resources, isLoading: ref(false) }),
  useCreateHangarPlanMelt: () => ({ mutateAsync: vi.fn() }),
  useUpdateHangarPlanMelt: () => ({ mutateAsync: vi.fn() }),
}));

vi.mock("@/frontend/composables/useHangarPlanCache", () => ({
  useHangarPlanCache: () => ({ updatePlan: vi.fn() }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit: vi.fn(), on: vi.fn(), off: vi.fn() }),
}));

const mount = (props: Record<string, unknown>) =>
  mountWithDefaults(Component, { props: { planId: "plan", ...props } });

describe("Hangar/Planner/MeltModal", () => {
  it("names the ship it melts and lists what melts with it", async () => {
    const wrapper = await mount({ vehicleId: "vehicle-cutlass" });

    expect(wrapper.find('[data-test="hangar-plan-melt-ship"]').text()).toBe(
      "Cutlass Black",
    );

    const contents = wrapper.find('[data-test="hangar-plan-melt-contents"]');
    expect(contents.text()).toContain("Package - Explorer Pack");
    expect(contents.text()).toContain("Carrack");
    expect(contents.text()).toContain("Carrack - Ghoul Paint");
    expect(contents.text()).toContain("×2");
    // Five items: the Cutlass, the Carrack, two paints, and one unlisted.
    expect(contents.text()).toContain("1 more item");
  });

  it("offers no ship to pick, only the one it was opened for", async () => {
    const wrapper = await mount({ vehicleId: "vehicle-aurora" });

    expect(wrapper.find('[data-test="pick-list-row"]').exists()).toBe(false);
  });

  it("lists nothing for a ship that is its pledge on its own", async () => {
    const wrapper = await mount({ vehicleId: "vehicle-aurora" });

    expect(
      wrapper.find('[data-test="hangar-plan-melt-contents"]').exists(),
    ).toBe(false);
  });

  it("warns where RSI says the pledge does not melt", async () => {
    const wrapper = await mount({ vehicleId: "vehicle-gift" });

    expect(
      wrapper.find('[data-test="hangar-plan-melt-ship"]').text(),
    ).toContain("not meltable");
  });
});
