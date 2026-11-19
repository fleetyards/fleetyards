import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount, flushPromises } from "@vue/test-utils";
import { createRouter, createMemoryHistory, type Router } from "vue-router";
import type { Feature } from "@/services/fyAdminApi";

const FEATURE_NAME = '[data-test="feature-name"]';
const FEATURE_ROW = '[data-test="feature-row"]';

function feature(overrides: Partial<Feature> = {}): Feature {
  return {
    name: "fleet_logistics",
    state: "off",
    permanent: false,
    selfServiceUser: false,
    selfServiceFleet: false,
    percentageOfActors: 0,
    percentageOfTime: 0,
    groups: [],
    actors: [],
    fullyOnSince: null,
    lastChangedAt: null,
    lastChangedBy: null,
    lastChangedSource: null,
    ...overrides,
  };
}

const features = vi.hoisted(() => ({
  value: undefined as Feature[] | undefined,
}));

const api = vi.hoisted(() => ({
  enableAdminFeature: vi.fn(),
  disableAdminFeature: vi.fn(),
}));

const loadFailed = vi.hoisted(() => ({ value: false }));

vi.mock("@/services/fyAdminApi", () => ({
  ...api,
  useAdminFeatures: () => ({
    data: features,
    isLoading: ref(false),
    isError: computed(() => loadFailed.value),
  }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string, options?: Record<string, unknown>) =>
      options ? `${key} ${JSON.stringify(options)}` : key,
    l: (value: string) => value,
    timeDistance: (value: string) => value,
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
      {
        path: "/features/:name/",
        name: "admin-feature",
        component: { template: "<div />" },
      },
    ],
  });

  await router.push({ name: "admin-features", query: tab ? { tab } : {} });
  await router.isReady();

  const wrapper = mount(FeaturesPage, {
    global: {
      plugins: [router],
      stubs: {
        Heading: { template: "<div><slot /></div>" },
        BasePill: { template: "<span><slot /></span>" },
        BtnGroup: { template: "<div><slot /></div>" },
        Btn: {
          emits: ["click"],
          template: "<button @click=\"$emit('click')\"><slot /></button>",
        },
        FormInput: {
          props: ["modelValue"],
          emits: ["update:modelValue"],
          template:
            "<input :value='modelValue' @input=\"$emit('update:modelValue', $event.target.value)\" />",
        },
      },
    },
  });

  await nextTick();

  return { wrapper, router };
};

function namesOn(wrapper: {
  findAll: (s: string) => { text: () => string }[];
}) {
  return wrapper.findAll(FEATURE_NAME).map((el) => el.text());
}

describe("AdminFeaturesPage", () => {
  beforeEach(() => {
    features.value = [
      feature({ name: "fleet_logistics" }),
      feature({ name: "oauth-discord", permanent: true }),
      feature({ name: "fleet_tours" }),
    ];
    loadFailed.value = false;
    api.enableAdminFeature.mockReset();
    api.disableAdminFeature.mockReset();
  });

  it("lists every flag without a tab in the query", async () => {
    const { wrapper } = await mountPage();

    expect(namesOn(wrapper)).toEqual([
      "fleet_logistics",
      "oauth-discord",
      "fleet_tours",
    ]);
  });

  it("lists only the permanent flags on the permanent tab", async () => {
    const { wrapper } = await mountPage("permanent");

    expect(namesOn(wrapper)).toEqual(["oauth-discord"]);
  });

  it("leaves the permanent flags out of the rollout tab", async () => {
    const { wrapper } = await mountPage("rollout");

    expect(namesOn(wrapper)).toEqual(["fleet_logistics", "fleet_tours"]);
  });

  it("falls back to every flag for a tab nobody has", async () => {
    const { wrapper } = await mountPage("nonsense");

    expect(namesOn(wrapper)).toHaveLength(3);
  });

  it("counts the flags behind each tab", async () => {
    const { wrapper } = await mountPage();

    expect(wrapper.find('[data-test="features-tab-all"]').text()).toContain(
      "3",
    );
    expect(
      wrapper.find('[data-test="features-tab-permanent"]').text(),
    ).toContain("1");
  });

  it("narrows the list to names matching the filter", async () => {
    const { wrapper } = await mountPage();

    await wrapper.find("input").setValue("TOURS");

    expect(namesOn(wrapper)).toEqual(["fleet_tours"]);
  });

  // How long a flag has been open is the removal signal the page exists to
  // surface, so which rows carry it matters.
  it("marks a fully open flag with how long it has been open", async () => {
    features.value = [
      feature({
        name: "friends",
        state: "on",
        fullyOnSince: "2026-01-01T00:00:00Z",
      }),
    ];

    const { wrapper } = await mountPage();

    expect(wrapper.find('[data-test="feature-kind"]').text()).toContain(
      "labels.features.openFor",
    );
  });

  // Being open for a year is the point of a permanent flag, not a symptom -- the
  // same reason bin/feature-flags stale skips them.
  it("leaves a permanent flag unmarked however long it has been open", async () => {
    features.value = [
      feature({
        name: "oauth-discord",
        state: "on",
        permanent: true,
        fullyOnSince: "2024-01-01T00:00:00Z",
      }),
    ];

    const { wrapper } = await mountPage();

    expect(wrapper.find('[data-test="feature-kind"]').text()).not.toContain(
      "labels.features.openFor",
    );
  });

  it("says who has each flag", async () => {
    features.value = [
      feature({ name: "off_flag" }),
      feature({ name: "on_flag", state: "on" }),
      feature({
        name: "partial_flag",
        state: "conditional",
        groups: ["testers"],
        percentageOfActors: 25,
      }),
    ];

    const { wrapper } = await mountPage();
    const onFor = wrapper
      .findAll('[data-test="feature-on-for"]')
      .map((el) => el.text());

    expect(onFor[0]).toBe("labels.features.nobody");
    expect(onFor[1]).toBe("labels.features.everyone");
    expect(onFor[2]).toContain("testers");
    expect(onFor[2]).toContain("labels.features.summary.percentOfUsers");
  });

  it("links each flag to a page of its own", async () => {
    const { wrapper } = await mountPage();

    expect(
      wrapper.findAll(FEATURE_ROW).map((el) => el.attributes("href")),
    ).toEqual([
      "/features/fleet_logistics/",
      "/features/oauth-discord/",
      "/features/fleet_tours/",
    ]);
  });

  // Switching a flag off clears every gate, which is too much for a button in a
  // list row.
  it("offers no way to switch a flag from the list", async () => {
    const { wrapper } = await mountPage();

    for (const row of wrapper.findAll(FEATURE_ROW)) {
      expect(row.find("button").exists()).toBe(false);
    }
  });

  it("puts the chosen tab in the query and takes it out again", async () => {
    const { wrapper, router } = await mountPage();

    await wrapper.find('[data-test="features-tab-permanent"]').trigger("click");
    await flushPromises();

    expect(router.currentRoute.value.query.tab).toBe("permanent");
    expect(namesOn(wrapper)).toEqual(["oauth-discord"]);

    await wrapper.find('[data-test="features-tab-all"]').trigger("click");
    await flushPromises();

    expect(router.currentRoute.value.query.tab).toBeUndefined();
  });

  describe("with nothing to show", () => {
    const EMPTY = '[data-test="features-empty"]';

    it("blames the filter when it hides every flag", async () => {
      const { wrapper } = await mountPage();

      await wrapper.find("input").setValue("nothing-like-this");

      expect(wrapper.find(EMPTY).text()).toBe("labels.features.noMatches");
    });

    it("says the registry is empty when it is", async () => {
      features.value = [];

      const { wrapper } = await mountPage();

      expect(wrapper.find(EMPTY).text()).toBe("labels.features.emptyRegistry");
    });

    it("says the load failed rather than that nothing matched", async () => {
      features.value = undefined;
      loadFailed.value = true;

      const { wrapper } = await mountPage();

      expect(wrapper.find(EMPTY).text()).toBe("labels.features.loadError");
    });
  });
});
