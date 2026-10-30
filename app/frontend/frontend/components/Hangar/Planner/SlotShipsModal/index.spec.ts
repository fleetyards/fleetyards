import { flushPromises } from "@vue/test-utils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  HangarPlanSlotStateEnum,
  type HangarPlan,
  type HangarPlanCandidate,
  type HangarPlanSlot,
} from "@/services/fyApi";
import Component from "./index.vue";

const candidate = (
  name: string,
  pledgePrice: number,
  attrs: Partial<HangarPlanCandidate> = {},
): HangarPlanCandidate => ({
  id: `candidate-${name}`,
  position: 0,
  model: {
    id: name,
    name,
    slug: name.toLowerCase(),
    onSale: true,
    ccuInto: "on_sale",
    ccuOutOf: "known",
    pledgePrice,
  },
  modelModuleIds: [],
  modelUpgradeIds: [],
  matchesFilters: true,
  ownedCount: 0,
  acquisitions: [],
  ...attrs,
});

const slot: HangarPlanSlot = {
  id: "slot",
  label: "Main hauler",
  quantity: 1,
  position: 0,
  state: HangarPlanSlotStateEnum.UNDECIDED,
  filters: {},
  candidates: [
    candidate("Hull A", 90),
    candidate("Caterpillar", 330, { matchesFilters: false }),
  ],
};

const plan = { id: "plan", slots: [slot] } as HangarPlan;
const planData = ref<HangarPlan>(plan);

const chooseMutate = vi.fn((_input: unknown) => Promise.resolve(plan));
const removeCandidateMutate = vi.fn((_input: unknown) => Promise.resolve(plan));
const removeSlotMutate = vi.fn((_input: unknown) => Promise.resolve(plan));
const updatePlan = vi.fn();
const comlinkEmit = vi.fn();

const mutation = (mutateAsync: unknown) => ({
  mutateAsync,
  isPending: ref(false),
});

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useHangarPlan: () => ({ data: planData }),
  useChooseHangarPlanSlotCandidate: () => mutation(chooseMutate),
  useDestroyHangarPlanCandidate: () => mutation(removeCandidateMutate),
  useDestroyHangarPlanSlot: () => mutation(removeSlotMutate),
}));

vi.mock("@/frontend/composables/useHangarPlanCache", () => ({
  useHangarPlanCache: () => ({ updatePlan, refreshDerived: vi.fn() }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit: comlinkEmit, on: vi.fn(), off: vi.fn() }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displayAlert: vi.fn(),
    displayConfirm: ({ onConfirm }: { onConfirm: () => void }) => onConfirm(),
  }),
}));

const mount = () =>
  mountWithDefaults(Component, { props: { planId: "plan", slot } });

describe("Hangar/Planner/SlotShipsModal", () => {
  beforeEach(() => {
    planData.value = plan;
    chooseMutate.mockClear();
    removeCandidateMutate.mockClear();
    removeSlotMutate.mockClear();
    updatePlan.mockClear();
    comlinkEmit.mockClear();
  });

  it("sets an undecided slot's ships side by side and marks the cheaper one", async () => {
    const wrapper = await mount();

    const cards = wrapper.findAll('[data-test="hangar-plan-slot-ship"]');
    expect(cards).toHaveLength(2);
    expect(cards[0].text()).toContain("best");
    expect(cards[1].text()).not.toContain("best");
    expect(cards[1].text()).toContain("outside this slot's filters");
    expect(
      wrapper.findAll('[data-test="hangar-plan-slot-ship-choose"]'),
    ).toHaveLength(2);
  });

  it("keeps the chosen ship and closes", async () => {
    const wrapper = await mount();

    await wrapper
      .findAll('[data-test="hangar-plan-slot-ship-choose"]')[1]
      .trigger("click");
    await flushPromises();

    expect(chooseMutate).toHaveBeenCalledWith({
      hangarPlanId: "plan",
      id: "slot",
      data: { candidateId: "candidate-Caterpillar" },
    });
    expect(updatePlan).toHaveBeenCalledWith(plan);
    expect(comlinkEmit).toHaveBeenCalledWith("close-modal", true);
  });

  it("removes a ship and shows the slot as it now stands", async () => {
    const wrapper = await mount();

    await wrapper
      .findAll('[data-test="hangar-plan-slot-ship-remove"]')[0]
      .trigger("click");
    await flushPromises();

    expect(removeCandidateMutate).toHaveBeenCalledWith({
      hangarPlanId: "plan",
      id: "candidate-Hull A",
    });
    expect(comlinkEmit).not.toHaveBeenCalledWith("close-modal", true);

    planData.value = {
      ...plan,
      slots: [
        {
          ...slot,
          state: HangarPlanSlotStateEnum.DECIDED,
          candidates: [slot.candidates[1]],
        },
      ],
    };
    await flushPromises();

    expect(wrapper.findAll('[data-test="hangar-plan-slot-ship"]')).toHaveLength(
      1,
    );
    expect(
      wrapper.find('[data-test="hangar-plan-slot-ship-choose"]').exists(),
    ).toBe(false);
  });

  it("removes the whole slot once confirmed", async () => {
    const wrapper = await mount();

    await wrapper
      .find('[data-test="hangar-plan-slot-ships-remove-slot"]')
      .trigger("click");
    await flushPromises();

    expect(removeSlotMutate).toHaveBeenCalledWith({
      hangarPlanId: "plan",
      id: "slot",
    });
    expect(comlinkEmit).toHaveBeenCalledWith("close-modal", true);
  });
});
