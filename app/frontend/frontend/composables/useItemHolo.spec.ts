import { describe, it, expect, vi } from "vitest";
import { type MediaFile } from "@/services/fyApi";

const flag = vi.hoisted(() => ({ enabled: true }));

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({ isFeatureEnabled: () => flag.enabled }),
}));

import { useItemHolo } from "./useItemHolo";

const file = (name: string, size = 1000): MediaFile => ({
  name,
  contentType: "model/gltf-binary",
  size,
  url: `https://example.test/${name}`,
});

const holos = { holo: file("holo.glb"), holoTextured: file("textured.glb") };

describe("useItemHolo", () => {
  it("shows the textured holo", () => {
    flag.enabled = true;
    const { holoModel } = useItemHolo(holos);

    expect(holoModel.value).toEqual({
      path: "https://example.test/textured.glb",
      size: 1000,
      textured: true,
    });
  });

  it("shows the plain holo without a textured one", () => {
    flag.enabled = true;
    const { holoModel } = useItemHolo({ holo: file("holo.glb") });

    expect(holoModel.value).toEqual({
      path: "https://example.test/holo.glb",
      size: 1000,
      textured: false,
    });
  });

  it("falls back to the plain holo once the textured one fails", () => {
    flag.enabled = true;
    const { holoModel, fallBackToPlainHolo } = useItemHolo(holos);

    expect(fallBackToPlainHolo()).toBe(true);
    expect(holoModel.value?.path).toBe("https://example.test/holo.glb");
    expect(fallBackToPlainHolo()).toBe(false);
  });

  it("tries the textured holo again for the next item", async () => {
    flag.enabled = true;
    const item = ref(holos);
    const { holoModel, fallBackToPlainHolo } = useItemHolo(item);

    fallBackToPlainHolo();
    item.value = { holo: file("other.glb"), holoTextured: file("other_t.glb") };
    await nextTick();

    expect(holoModel.value?.path).toBe("https://example.test/other_t.glb");
  });

  it("shows the plain holo while the flag is off", () => {
    flag.enabled = false;
    const { holoModel } = useItemHolo(holos);

    expect(holoModel.value?.path).toBe("https://example.test/holo.glb");
  });

  it("shows the plain holo where the textured one should not load", () => {
    flag.enabled = true;
    const { holoModel } = useItemHolo(holos, { canLoad: () => false });

    expect(holoModel.value?.textured).toBe(false);
  });
});
