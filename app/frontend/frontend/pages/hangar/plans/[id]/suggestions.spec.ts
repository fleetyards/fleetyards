import { describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  HangarPlanRedundancyKindEnum,
  HangarPlanSlotStateEnum,
  HangarPlanVehicleStatusEnum,
  type HangarPlan,
  type HangarPlanModel,
  type HangarPlanSuggestions,
} from "@/services/fyApi";
import { createRouter, createWebHashHistory } from "vue-router";
import Component from "./suggestions.vue";

const model = (name: string, pledgePrice: number): HangarPlanModel => ({
  id: name,
  name,
  slug: name.toLowerCase(),
  onSale: true,
  ccuInto: "on_sale",
  ccuOutOf: "known",
  pledgePrice,
});

const gladius = model("Gladius", 90);
const cutlass = model("Cutlass Black", 100);
const freelancer = model("Freelancer", 125);

const hauler = {
  id: "hauler",
  label: "Hauler",
  quantity: 1,
  position: 0,
  state: HangarPlanSlotStateEnum.DECIDED,
  filters: {},
  candidates: [],
};

const plan = ref({
  id: "plan",
  name: "Plan",
  slots: [hauler],
} as unknown as HangarPlan);

const suggestions = ref<HangarPlanSuggestions>({
  redundancies: [
    {
      kind: HangarPlanRedundancyKindEnum.DUPLICATE,
      model: gladius,
      entries: [
        {
          model: gladius,
          vehicleId: "vehicle-red-five",
          vehicleName: "Red Five",
          vehicleStatus: HangarPlanVehicleStatusEnum.PENDING,
        },
        { model: gladius, vehicleId: "vehicle-gladius" },
      ],
    },
    {
      kind: HangarPlanRedundancyKindEnum.ROLE,
      classificationLabel: "Transport",
      sizeLabel: "Medium",
      focusLabel: "Freight",
      entries: [
        { model: cutlass, vehicleId: "vehicle-cutlass" },
        { model: freelancer, slotId: "hauler", slotLabel: "Hauler" },
      ],
    },
  ],
});

const emit = vi.fn();

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useHangarPlan: () => ({ data: plan, isLoading: ref(false) }),
  useHangarPlanSuggestions: () => ({
    data: suggestions,
    isLoading: ref(false),
  }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit, on: vi.fn(), off: vi.fn() }),
}));

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    ["home", "/"],
    ["hangar", "/hangar/"],
    ["hangar-plans", "/hangar/plans/"],
    ["hangar-plan", "/hangar/plans/:id/"],
  ].map(([name, path]) => ({ name, path, component: { render: () => null } })),
});

const mount = () => mountWithDefaults(Component, { plugins: [router] });

describe("pages/hangar/plans/[id]/suggestions", () => {
  it("names the ships the plan holds twice and where each comes from", async () => {
    const wrapper = await mount();

    const duplicate = wrapper.find(
      '[data-test="hangar-plan-redundancy-duplicate"]',
    );
    expect(duplicate.text()).toContain("Gladius × 2");
    expect(duplicate.text()).toContain(
      "Your hangar · Red Five · Needs a decision",
    );

    const role = wrapper.find('[data-test="hangar-plan-redundancy-role"]');
    expect(role.text()).toContain("Freight · Medium · Transport");
    expect(role.text()).toContain("Slot Hauler");
  });

  it("melts a hangar ship and opens a slot from its ship", async () => {
    const wrapper = await mount();

    await wrapper
      .find('[data-test="hangar-plan-redundant-melt"]')
      .trigger("click");
    await wrapper
      .find('[data-test="hangar-plan-redundant-slot"]')
      .trigger("click");

    const [[, melt], [, slot]] = emit.mock.calls as [
      [string, { props: Record<string, unknown> }],
      [string, { props: Record<string, unknown> }],
    ];
    expect(melt.props).toMatchObject({ vehicleId: "vehicle-red-five" });
    expect(slot.props).toMatchObject({ slot: hauler });
  });
});
