import { flushPromises } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  HangarPlanSlotStateEnum,
  type HangarPlan,
  type HangarPlanSlot,
} from "@/services/fyApi";
import Component from "./index.vue";

const slot = (id: string): HangarPlanSlot => ({
  id,
  label: id,
  quantity: 2,
  position: 0,
  state: HangarPlanSlotStateEnum.OPEN,
  filters: { sizeIn: ["small"] },
  candidates: [],
});

const plan = ref({
  id: "plan",
  slots: [slot("Hauler"), slot("Explorer"), slot("Miner")],
} as unknown as HangarPlan);

const createMutate = vi.fn((_input: unknown) => Promise.resolve(plan.value));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useHangarPlan: () => ({ data: plan }),
  useCreateHangarPlanSlot: () => ({ mutateAsync: createMutate }),
  useUpdateHangarPlanSlot: () => ({ mutateAsync: vi.fn() }),
}));

vi.mock("@/frontend/composables/useHangarPlanCache", () => ({
  useHangarPlanCache: () => ({ updatePlan: vi.fn() }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit: vi.fn(), on: vi.fn(), off: vi.fn() }),
}));

describe("Hangar/Planner/SlotModal", () => {
  it("adds a slot by its name alone, numbered when left blank", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { planId: "plan" },
    });

    expect(wrapper.find('[name="quantity"]').exists()).toBe(false);
    expect(wrapper.find(".slot-filters").exists()).toBe(false);

    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(createMutate).toHaveBeenLastCalledWith({
      hangarPlanId: "plan",
      data: { label: "Slot 4" },
    });
  });

  it("edits a slot's count and filters", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { planId: "plan", slot: plan.value.slots[0] },
    });

    expect(wrapper.find('[name="quantity"]').exists()).toBe(true);
    expect(wrapper.find(".slot-filters").exists()).toBe(true);
  });
});
