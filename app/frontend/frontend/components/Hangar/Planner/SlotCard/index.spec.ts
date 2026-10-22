import { flushPromises } from "@vue/test-utils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  HangarPlanSlotStateEnum,
  HangarPlanStartKindEnum,
  type HangarPlan,
  type HangarPlanCandidate,
  type HangarPlanModel,
  type HangarPlanSlot,
} from "@/services/fyApi";
import Component from "./index.vue";

const plan = { id: "plan" } as HangarPlan;
const chooseMutate = vi.fn((_input: unknown) => Promise.resolve(plan));
const updatePlan = vi.fn();

const mutation = (mutateAsync = vi.fn()) => ({
  mutateAsync,
  isPending: ref(false),
});

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useChooseHangarPlanSlotCandidate: () => mutation(chooseMutate),
  useDestroyHangarPlanAcquisition: () => mutation(),
  useDestroyHangarPlanCandidate: () => mutation(),
  useDestroyHangarPlanSlot: () => mutation(),
}));

vi.mock("@/frontend/composables/useHangarPlanCache", () => ({
  useHangarPlanCache: () => ({ updatePlan, refreshDerived: vi.fn() }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit: vi.fn(), on: vi.fn(), off: vi.fn() }),
}));

const model = (name: string, pledgePrice = 100): HangarPlanModel => ({
  id: name,
  name,
  slug: name.toLowerCase(),
  onSale: true,
  pledgePrice,
});

const candidate = (
  name: string,
  attrs: Partial<HangarPlanCandidate> = {},
): HangarPlanCandidate => ({
  id: `candidate-${name}`,
  position: 0,
  model: model(name),
  modelModuleIds: [],
  modelUpgradeIds: [],
  matchesFilters: true,
  ownedCount: 0,
  acquisitions: [],
  ...attrs,
});

const slot = (attrs: Partial<HangarPlanSlot> = {}): HangarPlanSlot => ({
  id: "slot",
  label: "Main hauler",
  quantity: 1,
  position: 0,
  state: HangarPlanSlotStateEnum.OPEN,
  filters: {},
  candidates: [],
  ...attrs,
});

describe("Hangar/Planner/SlotCard", () => {
  beforeEach(() => {
    chooseMutate.mockClear();
    updatePlan.mockClear();
  });

  it("explains an open slot", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { planId: "plan", slot: slot() },
    });

    expect(wrapper.text()).toContain("No ship picked yet");
  });

  it("lets the user choose between the candidates of an undecided slot", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        planId: "plan",
        slot: slot({
          state: HangarPlanSlotStateEnum.UNDECIDED,
          candidates: [candidate("Hull A"), candidate("Caterpillar")],
        }),
      },
    });

    const choose = wrapper.findAll('[data-test="hangar-plan-choose"]');
    expect(choose).toHaveLength(2);

    await choose[1].trigger("click");
    await flushPromises();

    expect(chooseMutate).toHaveBeenCalledWith({
      hangarPlanId: "plan",
      id: "slot",
      data: { candidateId: "candidate-Caterpillar" },
    });
    expect(updatePlan).toHaveBeenCalledWith(plan);
  });

  it("counts the ships of a decided slot that have no route yet", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        planId: "plan",
        slot: slot({
          quantity: 3,
          state: HangarPlanSlotStateEnum.DECIDED,
          candidates: [
            candidate("Carrack", {
              acquisitions: [
                {
                  id: "route",
                  startKind: HangarPlanStartKindEnum.STORE,
                  startModel: model("Carrack", 600),
                  price: 600,
                  sourceMissing: false,
                  usesBuybackToken: false,
                  steps: [],
                },
              ],
            }),
          ],
        }),
      },
    });

    expect(wrapper.findAll('[data-test="hangar-plan-route"]')).toHaveLength(1);
    expect(wrapper.text()).toContain("2 ships have no route yet");
    expect(wrapper.find('[data-test="hangar-plan-add-route"]').exists()).toBe(
      true,
    );
  });

  it("shows what the slot is for and marks a ship outside its filters", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        planId: "plan",
        slot: slot({
          description: "Long trips with a snub",
          filters: { classificationIn: ["exploration"], onSaleEq: true },
          state: HangarPlanSlotStateEnum.UNDECIDED,
          candidates: [
            candidate("Carrack"),
            candidate("Cutlass", { matchesFilters: false }),
          ],
        }),
      },
    });

    expect(wrapper.text()).toContain("Long trips with a snub");
    expect(wrapper.text()).toContain("exploration");
    expect(
      wrapper.findAll('[data-test="hangar-plan-candidate-mismatch"]'),
    ).toHaveLength(1);
  });

  it("marks the cheapest and the roomiest undecided ship", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        planId: "plan",
        slot: slot({
          state: HangarPlanSlotStateEnum.UNDECIDED,
          candidates: [
            candidate("Hull A", {
              model: { ...model("Hull A", 90), cargo: 64 },
            }),
            candidate("Caterpillar", {
              model: { ...model("Caterpillar", 330), cargo: 576 },
            }),
          ],
        }),
      },
    });

    const cards = wrapper.findAll(".plan-slot__candidate");
    expect(
      cards[0].findAll('[data-test="hangar-plan-candidate-best"]'),
    ).toHaveLength(1);
    expect(cards[0].text()).toContain("$90");
    expect(
      cards[1].findAll('[data-test="hangar-plan-candidate-best"]'),
    ).toHaveLength(1);
    expect(cards[1].text()).toContain("576 SCU");
  });

  it("offers no edits on a shared plan", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        planId: "plan",
        readonly: true,
        slot: slot({
          quantity: 2,
          state: HangarPlanSlotStateEnum.UNDECIDED,
          candidates: [candidate("Hull A"), candidate("Caterpillar")],
        }),
      },
    });

    expect(wrapper.find('[data-test="hangar-plan-choose"]').exists()).toBe(
      false,
    );
    expect(
      wrapper.find('[data-test="hangar-plan-slot-add-candidates"]').exists(),
    ).toBe(false);
  });
});
