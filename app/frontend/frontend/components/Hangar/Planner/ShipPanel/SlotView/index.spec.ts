import { flushPromises } from "@vue/test-utils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  HangarPlanSlotStateEnum,
  type HangarPlan,
  type HangarPlanCandidate,
  type HangarPlanSlot,
  type ModelOption,
} from "@/services/fyApi";
import { createRouter, createWebHashHistory } from "vue-router";
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

const hullA = candidate("Hull A", 90);
const caterpillar = candidate("Caterpillar", 330, { matchesFilters: false });

const slot: HangarPlanSlot = {
  id: "slot",
  label: "Main hauler",
  quantity: 1,
  position: 0,
  state: HangarPlanSlotStateEnum.UNDECIDED,
  filters: { cargoGteq: 50 },
  starts: [],
  candidates: [hullA, caterpillar],
};

const plan = { id: "plan", slots: [slot] } as HangarPlan;
const planData = ref<HangarPlan>(plan);

const option = (name: string): ModelOption => ({
  id: name,
  name,
  slug: name.toLowerCase(),
  manufacturer: { name: "MISC", slug: "misc", code: "MISC" },
  classification: "transport",
  classificationLabel: "Transport",
  inHangar: false,
  onWishlist: false,
  media: {},
});

const options = ref({
  items: [option("Hull A"), option("Hull B")],
  meta: { pagination: { currentPage: 1, totalPages: 1, totalCount: 2 } },
});
const optionParams = vi.hoisted(() => vi.fn());

const chooseMutate = vi.fn((_input: unknown) => Promise.resolve(plan));
const createMutate = vi.fn((_input: unknown) => Promise.resolve(plan));
const removeCandidateMutate = vi.fn((_input: unknown) => Promise.resolve(plan));
const removeSlotMutate = vi.fn((_input: unknown) => Promise.resolve(plan));
const updateAcquisitionMutate = vi.fn((_input: unknown) =>
  Promise.resolve(plan),
);
const updatePlan = vi.fn();

const mutation = (mutateAsync: unknown) => ({
  mutateAsync,
  isPending: ref(false),
});

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useHangarPlan: () => ({ data: planData }),
  useHangarPlanResources: () => ({
    data: ref({ vehicles: [], upgrades: [], buybacks: [], storeModels: [] }),
  }),
  useModelOptions: (params: unknown) => {
    optionParams(params);
    return { data: options, isFetching: ref(false), isLoading: ref(false) };
  },
  useChooseHangarPlanSlotCandidate: () => mutation(chooseMutate),
  useCreateHangarPlanCandidate: () => mutation(createMutate),
  useDestroyHangarPlanCandidate: () => mutation(removeCandidateMutate),
  useDestroyHangarPlanSlot: () => mutation(removeSlotMutate),
  useUpdateHangarPlanAcquisition: () => mutation(updateAcquisitionMutate),
}));

vi.mock("@/frontend/composables/useHangarPlanCache", () => ({
  useHangarPlanCache: () => ({ updatePlan, refreshDerived: vi.fn() }),
}));

const displayAlert = vi.hoisted(() => vi.fn());

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displayAlert,
    displayConfirm: ({ onConfirm }: { onConfirm: () => void }) => onConfirm(),
  }),
}));

const router = createRouter({
  history: createWebHashHistory(),
  routes: ["home", "compare"].map((name) => ({
    path: name === "home" ? "/" : `/${name}/`,
    name,
    component: { render: () => null },
  })),
});

const mount = () =>
  mountWithDefaults(Component, {
    props: { planId: "plan", slot },
    plugins: [router],
  });

const catalogueRow = (
  wrapper: Awaited<ReturnType<typeof mount>>,
  name: string,
) =>
  wrapper
    .findAll('[data-test="hangar-plan-slot-catalogue-row"]')
    .find((row) => row.text().includes(name))!;

describe("Hangar/Planner/ShipPanel/SlotView", () => {
  beforeEach(() => {
    planData.value = plan;
    vi.clearAllMocks();
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

  it("links to the compare page with the slot's ships", async () => {
    const wrapper = await mount();

    expect(
      wrapper
        .find('[data-test="hangar-plan-slot-ships-compare"]')
        .attributes("href"),
    ).toBe("#/compare/?models=hull+a&models=caterpillar");
  });

  it("keeps the chosen ship and is done", async () => {
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
    expect(wrapper.emitted("done")).toHaveLength(1);
  });

  it("searches the catalogue within the slot's filters", async () => {
    await mount();

    const params = toValue(optionParams.mock.calls[0][0]) as {
      q: Record<string, unknown>;
    };
    expect(params.q).toMatchObject({
      cargoGteq: 50,
      playerOwnableEq: true,
      plannable: true,
    });
  });

  it("narrows the catalogue to the wishlist", async () => {
    const wrapper = await mount();
    const params = optionParams.mock.calls[0][0];

    expect(toValue(params).q).not.toHaveProperty("onWishlist");

    await wrapper
      .find('[data-test="hangar-plan-slot-filter-wishlist"] button')
      .trigger("click");

    expect(toValue(params).q).toMatchObject({
      onWishlist: true,
      plannable: true,
    });
  });

  it("adds a ship from the catalogue to the shortlist, and takes one off", async () => {
    const wrapper = await mount();

    expect(catalogueRow(wrapper, "Hull A").text()).toContain("Shortlisted");

    await catalogueRow(wrapper, "Hull B")
      .find('[data-test="hangar-plan-slot-catalogue-toggle"]')
      .trigger("click");
    await flushPromises();

    expect(createMutate).toHaveBeenCalledWith({
      hangarPlanId: "plan",
      data: { slotId: "slot", modelId: "Hull B" },
    });
    expect(wrapper.emitted("done")).toBeUndefined();

    await catalogueRow(wrapper, "Hull A")
      .find('[data-test="hangar-plan-slot-catalogue-toggle"]')
      .trigger("click");
    await flushPromises();

    expect(removeCandidateMutate).toHaveBeenCalledWith({
      hangarPlanId: "plan",
      id: "candidate-Hull A",
    });
  });

  it("moves a held start to the ship it comes closest to once one is added", async () => {
    const hullB = candidate("Hull B", 150);
    const holding = {
      ...slot,
      candidates: [hullA],
      starts: [{ id: "start", startModel: hullB.model }],
    } as unknown as HangarPlanSlot;
    planData.value = { ...plan, slots: [holding] };
    createMutate.mockResolvedValueOnce({
      ...plan,
      slots: [
        {
          ...holding,
          candidates: [{ ...hullA, acquisitions: [{ id: "start" }] }, hullB],
        },
      ],
    } as unknown as HangarPlan);

    const wrapper = await mountWithDefaults(Component, {
      props: { planId: "plan", slot: holding },
      plugins: [router],
    });

    await catalogueRow(wrapper, "Hull B")
      .find('[data-test="hangar-plan-slot-catalogue-toggle"]')
      .trigger("click");
    await flushPromises();

    expect(updateAcquisitionMutate).toHaveBeenCalledWith({
      hangarPlanId: "plan",
      id: "start",
      data: { candidateId: "candidate-Hull B" },
    });
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
    expect(wrapper.emitted("done")).toHaveLength(1);
  });

  it("opens the slot's settings", async () => {
    const wrapper = await mount();

    await wrapper
      .find('[data-test="hangar-plan-slot-settings"]')
      .trigger("click");

    expect(wrapper.emitted("settings")?.[0]).toEqual([slot]);
  });

  it("says so when moving a held start fails", async () => {
    const hullB = candidate("Hull B", 150);
    const holding = {
      ...slot,
      candidates: [hullA],
      starts: [{ id: "start", startModel: hullB.model }],
    } as unknown as HangarPlanSlot;
    planData.value = { ...plan, slots: [holding] };
    createMutate.mockResolvedValueOnce({
      ...plan,
      slots: [{ ...holding, candidates: [hullA, hullB] }],
    } as unknown as HangarPlan);
    updateAcquisitionMutate.mockRejectedValueOnce(new Error("422"));

    const wrapper = await mountWithDefaults(Component, {
      props: { planId: "plan", slot: holding },
      plugins: [router],
    });

    await catalogueRow(wrapper, "Hull B")
      .find('[data-test="hangar-plan-slot-catalogue-toggle"]')
      .trigger("click");
    await flushPromises();

    expect(displayAlert).toHaveBeenCalled();
    // The ship itself was added, so the plan shows it.
    expect(updatePlan).toHaveBeenCalledTimes(1);
  });
});
