import { flushPromises } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  type HangarPlan,
  type HangarPlanModel,
  type HangarPlanResources,
  HangarPlanStartKindEnum,
  HangarPlanUpgradeSourceEnum,
} from "@/services/fyApi";
import Component from "./index.vue";

const model = (name: string, pledgePrice: number): HangarPlanModel => ({
  id: name,
  name,
  slug: name.toLowerCase(),
  onSale: true,
  ccuInto: "on_sale",
  ccuOutOf: "known",
  pledgePrice,
});

const aurora = model("Aurora", 30);
const taurus = model("Taurus", 150);
const carrack = model("Carrack", 600);

const update = vi.hoisted(() => vi.fn(() => Promise.resolve({ id: "plan" })));
const updatePlan = vi.hoisted(() => vi.fn());

const resources = ref<HangarPlanResources>({
  vehicles: [],
  upgrades: [
    {
      id: "ccu-aurora",
      name: "Upgrade - Aurora to Taurus",
      quantity: 1,
      usedCount: 0,
      pledgeValue: 60,
      fromModel: aurora,
      toModel: taurus,
    },
  ],
  buybacks: [],
  bundled: [],
  storeModels: [aurora, taurus, carrack],
});

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useHangarPlanResources: () => ({ data: resources }),
  useUpdateHangarPlanAcquisition: () => ({ mutateAsync: update }),
}));

vi.mock("@/frontend/composables/useHangarPlanCache", () => ({
  useHangarPlanCache: () => ({ updatePlan }),
}));

const plan = {
  id: "plan",
  slots: [
    {
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
              id: "route",
              startKind: HangarPlanStartKindEnum.OWNED,
              startModel: aurora,
              price: 0,
              routeComplete: true,
              sourceMissing: false,
              usesBuybackToken: false,
              steps: [
                {
                  id: "step",
                  sourceKind: HangarPlanUpgradeSourceEnum.STORE,
                  fromModel: aurora,
                  toModel: carrack,
                  usesBuybackToken: false,
                  sourceMissing: false,
                  price: 570,
                },
              ],
            },
          ],
        },
      ],
    },
  ],
} as unknown as HangarPlan;

describe("Hangar/Planner/UpgradeFits", () => {
  it("applies a held upgrade to the route it makes cheaper in one click", async () => {
    const wrapper = await mountWithDefaults(Component, { props: { plan } });

    const fit = wrapper.find('[data-test="hangar-plan-upgrade-fit"]');
    expect(fit.text()).toContain("Aurora → Taurus");
    expect(fit.text()).toContain("Carrack");
    expect(fit.text()).toContain("$120");
    expect(
      fit.find('[data-test="hangar-plan-upgrade-fit-credit"]').text(),
    ).toBe("gives up $60 credit");

    await fit
      .find('[data-test="hangar-plan-upgrade-fit-apply"]')
      .trigger("click");
    await flushPromises();

    expect(update).toHaveBeenCalledWith({
      hangarPlanId: "plan",
      id: "route",
      data: {
        steps: [
          expect.objectContaining({
            sourceKind: "owned_ccu",
            hangarPledgeItemId: "ccu-aurora",
            toModelId: "Taurus",
          }),
          expect.objectContaining({
            sourceKind: "store",
            toModelId: "Carrack",
          }),
        ],
      },
    });
    expect(updatePlan).toHaveBeenCalledWith({ id: "plan" });
  });

  it("shows nothing when no held upgrade helps", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { plan: { ...plan, slots: [] } },
    });

    expect(
      wrapper.find('[data-test="hangar-plan-upgrade-fits"]').exists(),
    ).toBe(false);
  });
});
