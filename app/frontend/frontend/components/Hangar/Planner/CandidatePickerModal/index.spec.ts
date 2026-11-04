import type { SetupContext } from "vue";
import { flushPromises } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  HangarPlanCcuIntoEnum,
  HangarPlanCcuOutOfEnum,
  HangarPlanSlotStateEnum,
  type HangarPlan,
  type HangarPlanModel,
  type HangarPlanSlot,
} from "@/services/fyApi";
import Component from "./index.vue";

const updateMutate = vi.fn((_input: unknown) =>
  Promise.resolve({ id: "plan" } as HangarPlan),
);

const createMutate = vi.hoisted(() => vi.fn());
const pairStart = vi.hoisted(() => vi.fn(() => Promise.resolve(true)));

vi.mock("@/frontend/composables/useHangarPlanPairing", () => ({
  useHangarPlanPairing: () => ({ pairStart }),
}));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useCreateHangarPlanCandidate: () => ({ mutateAsync: createMutate }),
  useHangarPlan: () => ({ data: { value: undefined } }),
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
};

const hull: HangarPlanModel = {
  id: "hull-c",
  name: "Hull C",
  slug: "hull-c",
  onSale: false,
  pledgePrice: 250,
  ccuInto: HangarPlanCcuIntoEnum.SALES_ONLY,
  ccuOutOf: HangarPlanCcuOutOfEnum.KNOWN,
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

  it("bounds the ships by the start picked before the slot had one", async () => {
    await mountWithDefaults(Component, {
      props: {
        planId: "plan",
        slot,
        start: { kind: "owned", vehicleId: "vehicle-hull-c" },
        startModel: hull,
      },
    });

    expect(picker.query).toEqual({
      pledgePriceLteq: 400,
      sizeIn: ["medium"],
      playerOwnableEq: true,
      plannable: true,
      ccuTarget: true,
      pledgePriceGt: 250,
    });
  });

  it("saves the start with the ship picked for it", async () => {
    const start = { kind: "owned" as const, vehicleId: "vehicle-hull-c" };
    const candidate = {
      id: "candidate",
      model: { ...hull, id: "polaris", pledgePrice: 975 },
    };
    createMutate.mockResolvedValueOnce({
      slots: [{ ...slot, candidates: [candidate] }],
    });
    const wrapper = await mountWithDefaults(Component, {
      props: { planId: "plan", slot, start, startModel: hull },
    });

    wrapper
      .findComponent({ name: "ModelPickerModal" })
      .vm.$emit("submit", [{ option: { id: "polaris" } }]);
    await flushPromises();

    expect(pairStart).toHaveBeenCalledWith(candidate, start);
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
