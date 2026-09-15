import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount, flushPromises } from "@vue/test-utils";
import { createRouter, createMemoryHistory, type Router } from "vue-router";
import { VueQueryPlugin } from "@tanstack/vue-query";
import type { Feature } from "@/services/fyAdminApi";

const FEATURE_NAME = '[data-test="feature-name"]';

const feature = (overrides: Partial<Feature> = {}): Feature => ({
  name: "fleet_logistics",
  state: "off",
  permanent: false,
  selfServiceUser: false,
  selfServiceFleet: false,
  percentageOfActors: 0,
  percentageOfTime: 0,
  groups: [],
  actors: [],
  ...overrides,
});

const features = vi.hoisted(() => ({
  value: undefined as Feature[] | undefined,
}));

vi.mock("@/services/fyAdminApi", () => ({
  useAdminFeatures: () => ({ data: features, isLoading: ref(false) }),
  getAdminFeaturesQueryKey: () => ["features"],
  enableAdminFeature: vi.fn(),
  disableAdminFeature: vi.fn(),
  enableAdminFeatureActor: vi.fn(),
  disableAdminFeatureActor: vi.fn(),
  enableAdminFeatureGroup: vi.fn(),
  disableAdminFeatureGroup: vi.fn(),
  enableAdminFeaturePercentageOfActors: vi.fn(),
  enableAdminFeaturePercentageOfTime: vi.fn(),
  toggleAdminFeatureUserSelfService: vi.fn(),
  toggleAdminFeatureFleetSelfService: vi.fn(),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displaySuccess: vi.fn(),
    displayAlert: vi.fn(),
  }),
}));

import FeaturesPage from "./features.vue";

const mountPage = async (tab?: string) => {
  const router: Router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {
        path: "/features/",
        name: "admin-features",
        component: { template: "<div />" },
      },
    ],
  });

  await router.push({ name: "admin-features", query: tab ? { tab } : {} });
  await router.isReady();

  const wrapper = mount(FeaturesPage, {
    global: {
      plugins: [router, VueQueryPlugin],
      directives: { Tooltip: {} },
      stubs: {
        Heading: { template: "<div><slot /></div>" },
        BasePill: { template: "<span><slot /></span>" },
        Btn: { template: "<button><slot /></button>" },
        Toggle: true,
        BaseSelect: true,
        UserSelect: true,
        FleetSelect: true,
        TabNavView: {
          template: "<div><slot name='nav' /><slot name='content' /></div>",
        },
        InlineEditableList: {
          props: ["items"],
          template:
            "<div><div v-for='item in items' :key='item.id'><slot name='display' :item='item' /></div></div>",
        },
      },
    },
  });

  await nextTick();

  return { wrapper, router };
};

const namesOn = (wrapper: {
  findAll: (s: string) => { text: () => string }[];
}) => wrapper.findAll(FEATURE_NAME).map((el) => el.text());

describe("AdminFeaturesPage", () => {
  beforeEach(() => {
    features.value = [
      feature({ name: "fleet_logistics" }),
      feature({ name: "oauth-discord", permanent: true }),
      feature({ name: "tools_cargo_grids" }),
    ];
  });

  it("lists every flag without a tab in the query", async () => {
    const { wrapper } = await mountPage();

    expect(namesOn(wrapper)).toEqual([
      "fleet_logistics",
      "oauth-discord",
      "tools_cargo_grids",
    ]);
  });

  it("lists only the permanent flags on the permanent tab", async () => {
    const { wrapper } = await mountPage("permanent");

    expect(namesOn(wrapper)).toEqual(["oauth-discord"]);
  });

  it("leaves the permanent flags out of the rollout tab", async () => {
    const { wrapper } = await mountPage("rollout");

    expect(namesOn(wrapper)).toEqual(["fleet_logistics", "tools_cargo_grids"]);
  });

  it("falls back to every flag for a tab nobody has", async () => {
    const { wrapper } = await mountPage("nonsense");

    expect(namesOn(wrapper)).toHaveLength(3);
  });

  it("puts the chosen tab in the query and takes it out again", async () => {
    const { wrapper, router } = await mountPage();

    await wrapper.find('[data-test="tab-anchor-permanent"]').trigger("click");
    await flushPromises();

    expect(router.currentRoute.value.query.tab).toBe("permanent");
    expect(namesOn(wrapper)).toEqual(["oauth-discord"]);

    await wrapper.find('[data-test="tab-anchor-all"]').trigger("click");
    await flushPromises();

    expect(router.currentRoute.value.query.tab).toBeUndefined();
  });
});
