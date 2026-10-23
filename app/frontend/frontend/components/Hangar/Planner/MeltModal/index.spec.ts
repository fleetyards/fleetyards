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

const mount = () =>
  mountWithDefaults(Component, {
    props: { planId: "plan" },
  });

const row = (wrapper: Awaited<ReturnType<typeof mount>>, title: string) =>
  wrapper
    .findAll('[data-test="pick-list-row"]')
    .find((entry) => entry.text().includes(title));

describe("Hangar/Planner/MeltModal", () => {
  it("names the package a ship is part of, and only then", async () => {
    const wrapper = await mount();

    expect(row(wrapper, "Cutlass Black")?.text()).toContain(
      "Package - Explorer Pack",
    );
    expect(row(wrapper, "Aurora MR")?.text()).not.toContain("Standalone");
  });

  it("lists what melts with the picked ship", async () => {
    const wrapper = await mount();

    expect(
      wrapper.find('[data-test="hangar-plan-melt-contents"]').exists(),
    ).toBe(false);

    await row(wrapper, "Cutlass Black")?.trigger("click");

    const contents = wrapper.find('[data-test="hangar-plan-melt-contents"]');
    expect(contents.text()).toContain("Package - Explorer Pack");
    expect(contents.text()).toContain("Carrack");
    expect(contents.text()).toContain("Carrack - Ghoul Paint");
    expect(contents.text()).toContain("×2");
    // Five items: the Cutlass, the Carrack, two paints, and one unlisted.
    expect(contents.text()).toContain("1 more item");
  });

  it("lists nothing for a ship that is its pledge on its own", async () => {
    const wrapper = await mount();

    await row(wrapper, "Aurora MR")?.trigger("click");

    expect(
      wrapper.find('[data-test="hangar-plan-melt-contents"]').exists(),
    ).toBe(false);
  });
});
