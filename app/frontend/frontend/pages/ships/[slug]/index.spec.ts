import {
  afterAll,
  beforeAll,
  beforeEach,
  describe,
  expect,
  it,
  vi,
} from "vitest";
import { config, flushPromises, mount } from "@vue/test-utils";
import { createTestingPinia } from "@pinia/testing";
import { VueQueryPlugin } from "@tanstack/vue-query";
import { createMemoryHistory, createRouter } from "vue-router";
import { FeatureFlagName, type ModelExtended } from "@/services/fyApi";

const viewport = vi.hoisted(() => ({ phone: false }));
const flags = vi.hoisted(() => ({ enabled: [] as string[] }));

const holoViewerStub = vi.hoisted(() => ({
  name: "HoloViewer",
  props: ["models"],
  template: "<div />",
}));

vi.mock("@/shared/components/HoloViewer/index.vue", () => ({
  default: holoViewerStub,
}));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  useModelModules: () => ({ data: ref(undefined) }),
  useModelPaints: () => ({ data: ref(undefined) }),
}));

vi.mock("@/frontend/composables/useHangarItems", () => ({
  useHangarItems: () => ({}),
}));

vi.mock("@/frontend/composables/useWishlistItems", () => ({
  useWishlistItems: () => ({}),
}));

vi.mock("@/shared/composables/useMobile", () => ({
  useMobile: () => computed(() => viewport.phone),
}));

vi.mock("@/shared/composables/useLowPowerDevice", () => ({
  isLowPowerDevice: () => viewport.phone,
  useLowPowerDevice: () => computed(() => viewport.phone),
}));

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({
    isFeatureEnabled: (flag: string) => flags.enabled.includes(flag),
  }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key, toDollar: String }),
}));

vi.mock("@/shared/composables/useMetaInfo", () => ({
  useMetaInfo: () => ({ updateMetaInfo: vi.fn() }),
}));

import ShipPage from "./index.vue";

const model = {
  id: "model-1",
  name: "Ironclad",
  slug: "drak-ironclad",
  media: {
    holo: { url: "https://example.test/holo.glb", size: 28 },
    holoLite: { url: "https://example.test/holo_lite.glb", size: 9 },
    landedHolo: { url: "https://example.test/landed.glb", size: 28 },
    landedHoloLite: { url: "https://example.test/landed_lite.glb", size: 9 },
  },
  metrics: { length: 123, beam: 80, height: 40 },
  manufacturer: { id: "manufacturer-1", name: "Drake", slug: "drake" },
} as unknown as ModelExtended;

const mountPage = async () => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {
        path: "/ships/:slug/",
        name: "ship",
        component: { template: "<div />" },
      },
      { path: "/ships/", name: "ships", component: { template: "<div />" } },
      {
        path: "/ships/:slug/viewer/",
        name: "ship-viewer",
        component: { template: "<div />" },
      },
    ],
  });
  await router.push(`/ships/${model.slug}/`);
  await router.isReady();

  const wrapper = mount(ShipPage, {
    props: { model },
    shallow: true,
    global: {
      plugins: [
        createTestingPinia({
          initialState: { models: { holoviewerVisible: true } },
        }),
        VueQueryPlugin,
        router,
      ],
      directives: { Tooltip: {} },
      stubs: { HoloViewer: holoViewerStub },
    },
  });
  await flushPromises();

  return wrapper;
};

const holoPath = (wrapper: Awaited<ReturnType<typeof mountPage>>) =>
  wrapper
    .findAllComponents({ name: "HoloViewer" })
    .map((viewer) => viewer.props("models")[0].path);

beforeAll(() => {
  config.global.renderStubDefaultSlot = true;
});

afterAll(() => {
  config.global.renderStubDefaultSlot = false;
});

beforeEach(() => {
  viewport.phone = false;
  flags.enabled = [];
});

describe("ShipPage", () => {
  describe("on a phone", () => {
    beforeEach(() => {
      viewport.phone = true;
    });

    it("offers no 3D view while the phone holo is off", async () => {
      const wrapper = await mountPage();

      expect(wrapper.find("[data-test='model-holo-toggle']").exists()).toBe(
        false,
      );
      expect(holoPath(wrapper)).toEqual([]);
    });

    it("shows the lite holo once the phone holo is on", async () => {
      flags.enabled = [FeatureFlagName.HOLO_PHONE];

      const wrapper = await mountPage();

      expect(wrapper.find("[data-test='model-holo-toggle']").exists()).toBe(
        true,
      );
      expect(holoPath(wrapper)).toEqual(["https://example.test/holo_lite.glb"]);
    });

    it("folds the state switch into a menu beside the open holo", async () => {
      flags.enabled = [FeatureFlagName.HOLO_PHONE];

      const wrapper = await mountPage();

      expect(
        wrapper.find("[data-test='model-holo-states-menu']").exists(),
      ).toBe(true);
      expect(wrapper.find("[data-test='model-holo-states']").exists()).toBe(
        false,
      );
    });
  });

  it("keeps the 3D view on a desktop without the phone holo", async () => {
    const wrapper = await mountPage();

    expect(wrapper.find("[data-test='model-holo-toggle']").exists()).toBe(true);
    expect(wrapper.find("[data-test='model-holo-states']").exists()).toBe(true);
  });
});
