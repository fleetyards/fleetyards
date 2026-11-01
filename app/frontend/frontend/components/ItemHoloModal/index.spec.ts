import { describe, it, expect, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { type MediaFile } from "@/services/fyApi";

const device = vi.hoisted(() => ({ lowPower: false }));

vi.mock("@/shared/composables/useLowPowerDevice", () => ({
  useLowPowerDevice: () => ref(device.lowPower),
}));

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({ isFeatureEnabled: () => true }),
}));

vi.mock("@/shared/components/HoloViewer/Modal/index.vue", () => ({
  default: {
    name: "HoloViewerModal",
    props: ["models"],
    emits: ["unavailable"],
    template: "<div />",
  },
}));

import ItemHoloModal from "./index.vue";

const file = (name: string, size = 1000): MediaFile => ({
  name,
  contentType: "model/gltf-binary",
  size,
  url: `https://example.test/${name}`,
});

describe("ItemHoloModal", () => {
  it("falls back to the plain holo in a fresh viewer", async () => {
    const wrapper = mount(ItemHoloModal, {
      props: {
        media: { holo: file("holo.glb"), holoTextured: file("textured.glb") },
      },
    });
    const viewer = () => wrapper.findComponent({ name: "HoloViewerModal" });
    const first = viewer().vm;

    expect(viewer().props("models")).toEqual([
      expect.objectContaining({ textured: true }),
    ]);

    viewer().vm.$emit("unavailable");
    await nextTick();

    expect(viewer().props("models")).toEqual([
      expect.objectContaining({ path: "https://example.test/holo.glb" }),
    ]);
    expect(viewer().vm).not.toBe(first);
  });

  it("keeps a low-power device on the plain holo for a large textured one", () => {
    device.lowPower = true;
    const wrapper = mount(ItemHoloModal, {
      props: {
        media: {
          holo: file("holo.glb"),
          holoTextured: file("textured.glb", 100_000_000),
        },
      },
    });
    device.lowPower = false;

    expect(
      wrapper.findComponent({ name: "HoloViewerModal" }).props("models"),
    ).toEqual([
      expect.objectContaining({ path: "https://example.test/holo.glb" }),
    ]);
  });
});
