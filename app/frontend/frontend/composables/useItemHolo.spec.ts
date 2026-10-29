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
  it("starts on the plain holo and switches to the textured one", () => {
    flag.enabled = true;
    const { holoModel, toggleTexturedHolo } = useItemHolo(holos);

    expect(holoModel.value).toEqual(
      expect.objectContaining({ path: "https://example.test/holo.glb" }),
    );

    toggleTexturedHolo();

    expect(holoModel.value).toEqual({
      path: "https://example.test/textured.glb",
      size: 1000,
      textured: true,
    });
  });

  it("starts on the textured holo when asked to", () => {
    flag.enabled = true;
    const { holoModel } = useItemHolo(holos, { textured: true });

    expect(holoModel.value?.textured).toBe(true);
  });

  it("offers no textured holo while the flag is off", () => {
    flag.enabled = false;
    const { holoModel, texturedHoloAvailable } = useItemHolo(holos, {
      textured: true,
    });

    expect(texturedHoloAvailable.value).toBe(false);
    expect(holoModel.value?.path).toBe("https://example.test/holo.glb");
  });

  it("offers no textured holo the device should not load", () => {
    flag.enabled = true;
    const { texturedHoloAvailable } = useItemHolo(holos, {
      canLoad: () => false,
    });

    expect(texturedHoloAvailable.value).toBe(false);
  });
});
