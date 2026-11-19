import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount, flushPromises } from "@vue/test-utils";
import { QueryClient, VueQueryPlugin } from "@tanstack/vue-query";
import type { Feature } from "@/services/fyAdminApi";

const current = vi.hoisted(() => ({
  value: undefined as Feature | undefined,
}));

const api = vi.hoisted(() => ({
  enableAdminFeature: vi.fn(),
  disableAdminFeature: vi.fn(),
}));

vi.mock("@/services/fyAdminApi", () => ({
  ...api,
  useAdminFeature: () => ({ data: current }),
  getAdminFeaturesQueryKey: () => ["features"],
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    l: (value: string) => value,
    timeDistance: (value: string) => value,
  }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displaySuccess: vi.fn(),
    displayAlert: vi.fn(),
  }),
}));

vi.mock("vue-router", async (importOriginal) => ({
  ...(await importOriginal<typeof import("vue-router")>()),
  useRoute: () => ({ params: { name: "fleet_tours" } }),
}));

import FeaturePage from "./[name].vue";

function feature(overrides: Partial<Feature> = {}): Feature {
  return {
    name: "fleet_tours",
    state: "conditional",
    permanent: false,
    selfServiceUser: false,
    selfServiceFleet: false,
    percentageOfActors: 0,
    percentageOfTime: 0,
    groups: ["testers"],
    actors: [],
    fullyOnSince: null,
    lastChangedAt: null,
    lastChangedBy: null,
    lastChangedSource: null,
    ...overrides,
  };
}

const mountPage = () =>
  mount(FeaturePage, {
    global: {
      plugins: [[VueQueryPlugin, { queryClient: new QueryClient() }]],
      stubs: {
        AsyncData: { template: "<div><slot name='resolved' /></div>" },
        BreadCrumbs: true,
        Heading: { template: "<div><slot /></div>" },
        BasePill: { template: "<span><slot /></span>" },
        OnFor: true,
        RolloutPanel: true,
        ActorsPanel: true,
        FeatureHistory: true,
        Panel: { template: "<div><slot /></div>" },
        PanelHeading: { template: "<div><slot /></div>" },
        PanelBody: { template: "<div><slot /></div>" },
        Btn: {
          emits: ["click"],
          template: "<button @click=\"$emit('click')\"><slot /></button>",
        },
        BtnConfirm: {
          emits: ["confirm"],
          template: "<button @click=\"$emit('confirm')\"><slot /></button>",
        },
      },
    },
  });

const ENABLE = '[data-test="feature-enable"]';
const DISABLE = '[data-test="feature-disable"]';

describe("AdminFeaturePage", () => {
  beforeEach(() => {
    api.enableAdminFeature.mockReset().mockResolvedValue({});
    api.disableAdminFeature.mockReset().mockResolvedValue({});
  });

  it("opens a partly rolled out flag to everyone", async () => {
    current.value = feature();
    const wrapper = mountPage();

    await wrapper.find(ENABLE).trigger("click");
    await flushPromises();

    expect(api.enableAdminFeature).toHaveBeenCalledWith("fleet_tours");
  });

  it("turns a flag off only through the confirm", async () => {
    current.value = feature();
    const wrapper = mountPage();

    await wrapper.find(DISABLE).trigger("click");
    await flushPromises();

    expect(api.disableAdminFeature).toHaveBeenCalledWith("fleet_tours");
  });

  it("offers no open action for a flag already on for everyone", () => {
    current.value = feature({ state: "on" });
    const wrapper = mountPage();

    expect(wrapper.find(ENABLE).exists()).toBe(false);
    expect(wrapper.find(DISABLE).exists()).toBe(true);
  });

  it("offers no turn-off for a flag that is already off", () => {
    current.value = feature({ state: "off", groups: [] });
    const wrapper = mountPage();

    expect(wrapper.find(ENABLE).exists()).toBe(true);
    expect(wrapper.find(DISABLE).exists()).toBe(false);
  });
});
