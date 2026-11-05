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

const createMutate = vi.hoisted(() => vi.fn());
const moveMutate = vi.hoisted(() => vi.fn(() => Promise.resolve({})));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useCreateHangarPlanCandidate: () => ({ mutateAsync: createMutate }),
  useUpdateHangarPlanAcquisition: () => ({ mutateAsync: moveMutate }),
  useUpdateHangarPlanSlot: () => ({ mutateAsync: updateMutate }),
}));

const picker = vi.hoisted(() => ({ query: undefined as unknown }));

const picked = vi.hoisted(() => ({
  manufacturerIn: [],
  classificationIn: [],
  focusIn: ["mining"],
  sizeIn: ["small"],
  productionStatusIn: [],
}));

// The picker itself queries the catalogue; only what it is asked for and the
// actions it hands its caller matter here.
vi.mock("@/frontend/components/Models/PickerModal/index.vue", async () => {
  const { h } = await import("vue");

  return {
    default: {
      name: "ModelPickerModal",
      props: ["query"],
      setup: (props: { query: unknown }, { slots }: SetupContext) => {
        picker.query = props.query;

        return () => h("div", slots["filter-actions"]?.({ filters: picked }));
      },
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
  starts: [],
};

describe("Hangar/Planner/CandidatePickerModal", () => {
  it("offers only ships the plan can get, within the slot's filters", async () => {
    await mountWithDefaults(Component, { props: { planId: "plan", slot } });

    expect(picker.query).toEqual({
      pledgePriceLteq: 400,
      sizeIn: ["medium"],
      playerOwnableEq: true,
      plannable: true,
    });
  });

  it("moves a start the first ship took to the ship it can become", async () => {
    const ship = (id: string, pledgePrice: number) => ({
      id,
      name: id,
      slug: id,
      onSale: true,
      ccuInto: "on_sale",
      ccuOutOf: "known",
      pledgePrice,
    });
    const start = ship("start", 200);
    const cheap = {
      id: "cheap",
      model: ship("cheap", 100),
      acquisitions: [{ id: "held" }],
    };
    const dear = { id: "dear", model: ship("dear", 400), acquisitions: [] };
    createMutate.mockResolvedValue({
      slots: [{ id: slot.id, candidates: [cheap, dear] }],
    });

    const wrapper = await mountWithDefaults(Component, {
      props: {
        planId: "plan",
        slot: {
          ...slot,
          starts: [
            {
              id: "held",
              startKind: "owned",
              startModel: start,
              sourceMissing: false,
            },
          ],
        } as HangarPlanSlot,
      },
    });

    wrapper
      .findComponent({ name: "ModelPickerModal" })
      .vm.$emit("submit", [
        { option: { id: "cheap" } },
        { option: { id: "dear" } },
      ]);
    await flushPromises();

    expect(moveMutate).toHaveBeenCalledWith({
      hangarPlanId: "plan",
      id: "held",
      data: { candidateId: "dear" },
    });
  });

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
