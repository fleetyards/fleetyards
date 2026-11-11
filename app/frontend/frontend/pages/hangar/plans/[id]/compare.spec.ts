import { describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  HangarPlanModelChangeEnum,
  type HangarPlan,
  type HangarPlanCompare,
  type HangarPlanModelDiff,
} from "@/services/fyApi";
import { createRouter, createWebHashHistory } from "vue-router";
import Component from "./compare.vue";

const diff = (
  name: string,
  leftCount: number,
  rightCount: number,
): HangarPlanModelDiff =>
  ({
    model: { id: name, name, slug: name.toLowerCase() },
    leftCount,
    rightCount,
    change:
      leftCount === rightCount
        ? HangarPlanModelChangeEnum.UNCHANGED
        : leftCount === 0
          ? HangarPlanModelChangeEnum.ADDED
          : rightCount === 0
            ? HangarPlanModelChangeEnum.REMOVED
            : rightCount > leftCount
              ? HangarPlanModelChangeEnum.MORE
              : HangarPlanModelChangeEnum.FEWER,
  }) as HangarPlanModelDiff;

const models = [
  diff("Carrack", 1, 1),
  diff("Polaris", 0, 3),
  ...Array.from({ length: 11 }, (_, index) => diff(`Ship ${index}`, 0, 1)),
];

const compare = ref({
  otherPlanId: "other",
  otherPlanName: "Lean",
  models,
  totals: { left: {}, right: {} },
  metrics: { left: {}, right: {} },
} as unknown as HangarPlanCompare);

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useHangarPlan: () => ({
    data: ref({ id: "plan", name: "Plan" } as HangarPlan),
  }),
  useCompareHangarPlans: () => ({ data: compare, isLoading: ref(false) }),
}));

vi.mock("@/frontend/components/Hangar/Planner/MetricsTable/index.vue", () => ({
  default: { render: () => null },
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

const rows = (wrapper: Awaited<ReturnType<typeof mount>>) =>
  wrapper.findAll('[data-test="hangar-plan-compare-diff"]');

describe("pages/hangar/plans/[id]/compare", () => {
  it("shows the biggest changes first and the rest on request", async () => {
    const wrapper = await mount();

    expect(rows(wrapper)).toHaveLength(10);
    expect(rows(wrapper)[0].text()).toContain("Polaris");
    expect(wrapper.text()).not.toContain("Carrack");

    const more = wrapper.find('[data-test="hangar-plan-compare-more"]');
    expect(more.text()).toBe("Show 2 more changes");

    await more.trigger("click");

    expect(rows(wrapper)).toHaveLength(12);
    expect(more.text()).toBe("Show fewer");
  });
});
