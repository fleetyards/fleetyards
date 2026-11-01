import { describe, it, expect, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { type MediaFile } from "@/services/fyApi";

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

const file = (name: string): MediaFile => ({
  name,
  contentType: "model/gltf-binary",
  size: 1000,
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
});
