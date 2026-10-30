import type { SetupContext } from "vue";
import { flushPromises } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  HangarPlanSlotStateEnum,
  type HangarPlan,
  type HangarPlanSlot,
} from "@/services/fyApi";
import Component from "./index.vue";

const updateMutate = vi.fn((_input: unknown) =>
  Promise.resolve({ id: "plan" } as HangarPlan),
);

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useCreateHangarPlanCandidate: () => ({ mutateAsync: vi.fn() }),
  useUpdateHangarPlanSlot: () => ({ mutateAsync: updateMutate }),
}));

const picked = vi.hoisted(() => ({
  manufacturerIn: [],
  classificationIn: [],
  focusIn: ["mining"],
  sizeIn: ["small"],
  productionStatusIn: [],
}));

// The picker itself queries the catalogue; only the actions it hands its
// caller matter here.
vi.mock("@/frontend/components/Models/PickerModal/index.vue", async () => {
  const { h } = await import("vue");

  return {
    default: {
      name: "ModelPickerModal",
      setup:
        (_props: unknown, { slots }: SetupContext) =>
        () =>
          h("div", slots["filter-actions"]?.({ filters: picked })),
    },
  };
});

vi.mock("@/frontend/composables/useHangarPlanCache", () => ({
  useHangarPlanCache: () => ({ updatePlan: vi.fn() }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit: vi.fn(), on: vi.fn(), off: vi.fn() }),
}));

const slot: HangarPlanSlot = {
  id: "mining",
  label: "Solo Miner",
  quantity: 1,
  position: 0,
  state: HangarPlanSlotStateEnum.OPEN,
  filters: { pledgePriceLteq: 400, sizeIn: ["medium"] },
  candidates: [],
};

describe("Hangar/Planner/CandidatePickerModal", () => {
  it("saves the filters picked as the slot's own", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { planId: "plan", slot },
    });

    await wrapper
      .find('[data-test="hangar-plan-save-slot-filters"]')
      .trigger("click");
    await flushPromises();

    expect(updateMutate).toHaveBeenLastCalledWith({
      hangarPlanId: "plan",
      id: "mining",
      data: {
        filters: {
          pledgePriceLteq: 400,
          sizeIn: ["small"],
          focusIn: ["mining"],
        },
      },
    });
  });
});
