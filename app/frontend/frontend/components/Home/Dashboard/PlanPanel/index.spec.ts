import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { computed, defineComponent, h, ref } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import type { HangarPlanListItem } from "@/services/fyApi";
import Component from "./index.vue";

const NAMES = ["hangar-plans", "hangar-plan"];

const Stub = defineComponent({ render: () => h("div") });

const router = async () => {
  const instance = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: Stub },
      ...NAMES.map((name) => ({
        path: `/${name}/:id?/:slug?`,
        name,
        component: Stub,
      })),
    ],
  });

  await instance.push("/");
  await instance.isReady();

  return instance;
};

let plans: HangarPlanListItem[] = [];

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useHangarPlans: () => ({
      data: computed(() => plans),
      isLoading: ref(false),
      isFetching: ref(false),
      isLoadingError: ref(false),
    }),
  };
});

const plan = (overrides: Partial<HangarPlanListItem>): HangarPlanListItem => ({
  id: "p1",
  name: "Road to the Polaris",
  basedOnAt: "2026-11-01T00:00:00Z",
  shared: false,
  slotsCount: 5,
  createdAt: "2026-11-01T00:00:00Z",
  updatedAt: "2026-11-01T00:00:00Z",
  ...overrides,
});

describe("HomeDashboardPlanPanel", () => {
  beforeEach(() => {
    plans = [];
  });

  it("pitches the planner to a pilot without a plan", async () => {
    const subject = await mountWithDefaults(Component, {
      plugins: [await router()],
    });

    expect(subject.find('[data-test="home-plan-pitch"]').text()).toContain(
      "Start a plan",
    );
  });

  it("shows the plan touched last", async () => {
    plans = [
      plan({ id: "old", name: "Old plan" }),
      plan({ id: "new", name: "New plan", updatedAt: "2026-11-10T00:00:00Z" }),
    ];

    const subject = await mountWithDefaults(Component, {
      plugins: [await router()],
    });

    expect(subject.find(".home-plan__name").text()).toBe("New plan");
    expect(subject.find(".home-plan__more").text()).toContain("1 more plan");
  });
});
