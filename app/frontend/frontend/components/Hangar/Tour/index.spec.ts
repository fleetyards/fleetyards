import { mount, type VueWrapper } from "@vue/test-utils";
import { createTestingPinia } from "@pinia/testing";
import { afterEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h } from "vue";
import PrimaryAction from "@/shared/components/PrimaryAction/index.vue";
import type { TourStep } from "@/shared/components/Tour/types";
import HangarTour from "./index.vue";

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

const originalMatchMedia = window.matchMedia;

const setViewport = (phone: boolean) => {
  window.matchMedia = ((query: string) => ({
    matches: phone,
    media: query,
    addEventListener: () => {},
    removeEventListener: () => {},
  })) as unknown as typeof window.matchMedia;
};

afterEach(() => {
  wrapper?.unmount();
  window.matchMedia = originalMatchMedia;
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

  it("includes every hangar feature in the guide", () => {
    const ids = steps().map((step) => step.id);

    expect(ids).toEqual(expect.arrayContaining(["overview", "pages", "reset"]));
  });

  it("anchors the ship page to its title and skips it without a ship", () => {
    const overview = steps().find((step) => step.id === "overview");

    expect(overview).toMatchObject({
      target: '[data-tour="vehicle-overview"]',
      requiresTarget: true,
    });
  });

  it("points the hangar pages at the navigation on a desktop", () => {
    setViewport(false);

    expect(steps().find((step) => step.id === "pages")).toMatchObject({
      target: '[data-test="nav-hangar-menu"]',
    });
  });

  it("explains the hangar pages on a phone without a target", () => {
    setViewport(true);

    const pages = steps().find((step) => step.id === "pages");

    expect(pages).toBeDefined();
    expect(pages?.target).toBeUndefined();
  });

  it("explains sharing when the public share button is absent", () => {
    const share = steps().find((step) => step.id === "share");

    expect(share).toBeDefined();
    expect(share?.requiresTarget).not.toBe(true);
  });
});
