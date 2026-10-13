import { mount, type VueWrapper } from "@vue/test-utils";
import { createTestingPinia } from "@pinia/testing";
import { afterEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h } from "vue";
import PrimaryAction from "@/shared/components/PrimaryAction/index.vue";
import type { TourStep } from "@/shared/components/Tour/types";
import { FeatureFlagName } from "@/services/fyApi";
import HangarTour from "./index.vue";

const { enabledFeatures } = vi.hoisted(() => ({
  enabledFeatures: new Set<string>(),
}));

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({
    isFeatureEnabled: (feature: string) => enabledFeatures.has(feature),
  }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

const TourStub = defineComponent({
  props: { steps: { type: Array, required: true } },
  render: () => null,
});

let wrapper: VueWrapper | undefined;

const steps = () => {
  wrapper = mount(HangarTour, {
    global: {
      plugins: [createTestingPinia()],
      stubs: { Tour: TourStub },
    },
  });

  return wrapper.findComponent(TourStub).props("steps") as TourStep[];
};

afterEach(() => {
  wrapper?.unmount();
  enabledFeatures.clear();
});

describe("HangarTour", () => {
  it("highlights the add button rather than its full-width container", () => {
    const add = steps().find((step) => step.id === "add");
    const action = mount(PrimaryAction, {
      props: { action: vi.fn() },
      attrs: { "data-tour": "hangar-add" },
      global: {
        stubs: { Btn: defineComponent({ render: () => h("button") }) },
        directives: { tooltip: () => {} },
      },
    });

    try {
      expect(add?.target).toBeDefined();
      expect(add?.scrollIntoView).toBe(false);
      expect(action.element.querySelector(add!.target!)).toBe(
        action.get("button").element,
      );
    } finally {
      action.unmount();
    }
  });

  it("leaves unavailable features out of the guide", () => {
    const ids = steps().map((step) => step.id);

    expect(ids).not.toContain("overview");
    expect(ids).not.toContain("inventories");
    expect(ids).toEqual(expect.arrayContaining(["pledgeItems", "reset"]));
  });

  it("anchors the ship page to its title and skips it without a ship", () => {
    enabledFeatures.add(FeatureFlagName.VEHICLE_OVERVIEW);
    const overview = steps().find((step) => step.id === "overview");

    expect(overview).toMatchObject({
      target: '[data-tour="vehicle-overview"]',
      requiresTarget: true,
    });
  });

  it("explains inventories on a phone without the desktop button", () => {
    enabledFeatures.add(FeatureFlagName.HANGAR_INVENTORIES);
    const inventories = steps().find((step) => step.id === "inventories");

    expect(inventories).toBeDefined();
    expect(inventories?.requiresTarget).not.toBe(true);
  });

  it("explains sharing when the public share button is absent", () => {
    const share = steps().find((step) => step.id === "share");

    expect(share).toBeDefined();
    expect(share?.requiresTarget).not.toBe(true);
  });
});
