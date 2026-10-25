import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { mount, type VueWrapper } from "@vue/test-utils";
import { createTestingPinia } from "@pinia/testing";
import Component from "./index.vue";

const state = vi.hoisted(() => ({
  authenticated: true,
  features: ["hangar_inventories"],
  emit: vi.fn(),
}));

vi.mock("@/frontend/stores/session", async () => {
  const { reactive } = await import("vue");

  return {
    useSessionStore: () => reactive({ isAuthenticated: state.authenticated }),
  };
});

vi.mock("pinia", async (importOriginal) => {
  const { toRefs } = await import("vue");

  return {
    ...(await importOriginal<typeof import("pinia")>()),
    storeToRefs: toRefs,
  };
});

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({
    isFeatureEnabled: (feature: string) => state.features.includes(feature),
  }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit: state.emit }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

const bulwark = {
  type: "Component",
  record: { id: "bulwark", name: "Bulwark", retired: false },
};

let wrapper: VueWrapper | undefined;

const mountBtn = (entry: Record<string, unknown> = bulwark) => {
  wrapper = mount(Component, {
    props: { entry: entry as never },
    global: { plugins: [createTestingPinia()], stubs: { teleport: true } },
  });

  return wrapper;
};

const button = (subject: VueWrapper) =>
  subject.find("[data-test='add-to-inventory']");

beforeEach(() => {
  state.authenticated = true;
  state.features = ["hangar_inventories"];
  state.emit.mockReset();
});

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

describe("LogisticsAddToInventoryBtn", () => {
  it("opens the deposit with the item named", async () => {
    const subject = mountBtn();

    await button(subject).trigger("click");

    expect(state.emit).toHaveBeenCalledWith(
      "open-modal",
      expect.objectContaining({
        props: {
          item: {
            item: {
              type: "Component",
              id: "bulwark",
              name: "Bulwark",
              counted: undefined,
            },
            name: "Bulwark",
            category: "component",
          },
        },
      }),
    );
  });

  it("is not offered to a visitor", () => {
    state.authenticated = false;

    expect(button(mountBtn()).exists()).toBe(false);
  });

  it("is offered for fleet inventories alone", () => {
    state.features = ["fleet_logistics"];

    expect(button(mountBtn()).exists()).toBe(true);
  });

  it("is not offered without any inventories", () => {
    state.features = [];

    expect(button(mountBtn()).exists()).toBe(false);
  });

  // The pickers stop offering a record the current build dropped.
  it("is not offered for a retired item", () => {
    const subject = mountBtn({
      ...bulwark,
      record: { ...bulwark.record, retired: true },
    });

    expect(button(subject).exists()).toBe(false);
  });
});
