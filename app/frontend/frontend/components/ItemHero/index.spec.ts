import { describe, it, expect, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { type MediaFile } from "@/services/fyApi";

const device = vi.hoisted(() => ({ mobile: false, lowPower: false }));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

vi.mock("@/shared/composables/useMobile", () => ({
  useMobile: () => ref(device.mobile),
}));

vi.mock("@/shared/composables/useLowPowerDevice", () => ({
  useLowPowerDevice: () => ref(device.lowPower),
}));

// The real viewer pulls in three.js, which does not load outside a browser.
vi.mock("@/shared/components/HoloViewer/index.vue", () => ({
  default: { name: "HoloViewer", template: "<div />" },
}));

import ItemHero from "./index.vue";

const file = (name: string, size = 1000): MediaFile => ({
  name,
  contentType: "image/webp",
  size,
  url: `https://example.test/${name}`,
  largeUrl: `https://example.test/large/${name}`,
});

const mountHero = (
  props: { image?: MediaFile; holo?: MediaFile },
  { mobile = false, lowPower = false } = {},
) => {
  device.mobile = mobile;
  device.lowPower = lowPower;

  return mount(ItemHero, {
    props: { ...props, name: "P4-AR Rifle", testId: "item-image" },
    global: {
      stubs: {
        HoloViewer: true,
        Btn: { template: "<button><slot /></button>" },
      },
      directives: { tooltip: {} },
    },
  });
};

describe("ItemHero", () => {
  it("shows the holo with a full screen button on a desktop", () => {
    const wrapper = mountHero({
      image: file("angled.webp"),
      holo: file("holo.glb"),
    });

    expect(wrapper.find("[data-test='item-image-holo']").exists()).toBe(true);
    expect(wrapper.find("[data-test='item-image-fullscreen']").exists()).toBe(
      true,
    );
    expect(wrapper.find("[data-test='item-image']").exists()).toBe(false);
  });

  it("keeps a phone on the picture", () => {
    const wrapper = mountHero(
      { image: file("angled.webp"), holo: file("holo.glb") },
      { mobile: true },
    );

    expect(wrapper.find("[data-test='item-image-holo']").exists()).toBe(false);
    expect(wrapper.find("[data-test='item-image']").attributes("src")).toBe(
      "https://example.test/large/angled.webp",
    );
  });

  it("keeps a low-power device on the picture for a large holo", () => {
    const wrapper = mountHero(
      { image: file("angled.webp"), holo: file("holo.glb", 100_000_000) },
      { lowPower: true },
    );

    expect(wrapper.find("[data-test='item-image-holo']").exists()).toBe(false);
  });

  it("renders nothing without a picture or a holo", () => {
    const wrapper = mountHero({});

    expect(wrapper.html()).toBe("<!--v-if-->");
  });
});
