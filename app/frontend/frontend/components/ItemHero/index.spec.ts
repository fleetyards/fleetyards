import { describe, it, expect, vi } from "vitest";
import { flushPromises, mount } from "@vue/test-utils";
import { type MediaFile } from "@/services/fyApi";

const device = vi.hoisted(() => ({
  mobile: false,
  lowPower: false,
  texturedHolo: true,
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

vi.mock("@/shared/composables/useMobile", () => ({
  useMobile: () => ref(device.mobile),
}));

vi.mock("@/shared/composables/useLowPowerDevice", () => ({
  useLowPowerDevice: () => ref(device.lowPower),
}));

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({ isFeatureEnabled: () => device.texturedHolo }),
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
  props: { image?: MediaFile; holo?: MediaFile; holoTextured?: MediaFile },
  { mobile = false, lowPower = false, texturedHolo = true } = {},
) => {
  device.mobile = mobile;
  device.lowPower = lowPower;
  device.texturedHolo = texturedHolo;

  return mount(ItemHero, {
    props: { ...props, name: "P4-AR Rifle", testId: "item-image" },
    global: {
      stubs: {
        HoloViewer: {
          name: "HoloViewer",
          props: ["models"],
          template: "<div />",
        },
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

  it("falls back to the picture when the holo cannot be shown", async () => {
    const wrapper = mountHero({
      image: file("angled.webp"),
      holo: file("holo.glb"),
    });
    await flushPromises();

    wrapper.findComponent({ name: "HoloViewer" }).vm.$emit("unavailable");
    await nextTick();

    expect(wrapper.find("[data-test='item-image-holo']").exists()).toBe(false);
    expect(wrapper.find("[data-test='item-image']").exists()).toBe(true);
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

  it("switches the holo to the textured one and back", async () => {
    const wrapper = mountHero({
      holo: file("holo.glb"),
      holoTextured: file("holo_textured.glb"),
    });
    const toggle = wrapper.find("[data-test='item-image-holo-textured']");
    const models = () =>
      wrapper.findComponent({ name: "HoloViewer" }).props("models");

    expect(models()).toEqual([
      expect.objectContaining({
        path: "https://example.test/holo.glb",
        textured: false,
      }),
    ]);

    await toggle.trigger("click");

    expect(models()).toEqual([
      expect.objectContaining({
        path: "https://example.test/holo_textured.glb",
        textured: true,
      }),
    ]);

    await toggle.trigger("click");

    expect(models()).toEqual([
      expect.objectContaining({ path: "https://example.test/holo.glb" }),
    ]);
  });

  it("falls back to the plain holo when the textured one cannot be shown", async () => {
    const wrapper = mountHero({
      image: file("angled.webp"),
      holo: file("holo.glb"),
      holoTextured: file("holo_textured.glb"),
    });
    const viewer = () => wrapper.findComponent({ name: "HoloViewer" });

    await wrapper
      .find("[data-test='item-image-holo-textured']")
      .trigger("click");
    viewer().vm.$emit("unavailable");
    await nextTick();

    expect(viewer().props("models")).toEqual([
      expect.objectContaining({ path: "https://example.test/holo.glb" }),
    ]);
    expect(wrapper.find("[data-test='item-image']").exists()).toBe(false);
  });

  it("leaves the switch out without a textured holo", () => {
    const wrapper = mountHero({ holo: file("holo.glb") });

    expect(
      wrapper.find("[data-test='item-image-holo-textured']").exists(),
    ).toBe(false);
  });

  it("leaves the switch out on a low-power device for a large textured holo", () => {
    const wrapper = mountHero(
      {
        holo: file("holo.glb"),
        holoTextured: file("holo_textured.glb", 100_000_000),
      },
      { lowPower: true },
    );

    expect(
      wrapper.find("[data-test='item-image-holo-textured']").exists(),
    ).toBe(false);
  });

  it("starts the next item on its plain holo", async () => {
    const wrapper = mountHero({
      holo: file("holo.glb"),
      holoTextured: file("holo_textured.glb"),
    });

    await wrapper
      .find("[data-test='item-image-holo-textured']")
      .trigger("click");
    await wrapper.setProps({
      holo: file("other.glb"),
      holoTextured: file("other_textured.glb"),
    });

    expect(
      wrapper.findComponent({ name: "HoloViewer" }).props("models"),
    ).toEqual([
      expect.objectContaining({ path: "https://example.test/other.glb" }),
    ]);
  });

  it("leaves the switch out while the flag is off", () => {
    const wrapper = mountHero(
      { holo: file("holo.glb"), holoTextured: file("holo_textured.glb") },
      { texturedHolo: false },
    );

    expect(
      wrapper.find("[data-test='item-image-holo-textured']").exists(),
    ).toBe(false);
  });

  it("renders nothing without a picture or a holo", () => {
    const wrapper = mountHero({});

    expect(wrapper.html()).toBe("<!--v-if-->");
  });
});
