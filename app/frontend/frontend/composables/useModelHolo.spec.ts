import { describe, expect, it, vi } from "vitest";
import type { MediaFile, Model, ModelPaint } from "@/services/fyApi";
import { ModelStateEnum } from "@/frontend/composables/useModelStates";

const lowPower = vi.hoisted(() => ({ value: false }));
const paints = vi.hoisted(() => ({ value: [] as unknown[] }));

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({ isFeatureEnabled: () => true }),
}));

vi.mock("@/shared/composables/useLowPowerDevice", () => ({
  isLowPowerDevice: () => lowPower.value,
}));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  useModelPaints: () => ({ data: ref(paints.value) }),
}));

const { useModelHolo } = await import("./useModelHolo");

const file = (name: string, size = 1000): MediaFile => ({
  name,
  contentType: "model/gltf-binary",
  size,
  url: `https://example.test/${name}`,
});

const model = (media: Record<string, MediaFile>) =>
  ({
    slug: "ironclad",
    metrics: { fleetchartOffsetLength: 98 },
    media,
  }) as unknown as Model;

const textured = {
  holo: file("holo.glb"),
  holoTextured: file("textured.glb", 54),
  holoTexturedLite: file("textured_lite.glb", 38),
  holoTexture: file("livery.webp"),
  holoTextureLite: file("livery_lite.webp"),
};

describe("useModelHolo", () => {
  it("falls back from the full textured export to the lite one", () => {
    lowPower.value = false;
    const { holoModel } = useModelHolo(model(textured), ModelStateEnum.FLIGHT, {
      textured: true,
    });

    expect(holoModel.value).toMatchObject({
      path: "https://example.test/textured.glb",
      paint: "https://example.test/livery.webp",
      fallback: {
        path: "https://example.test/textured_lite.glb",
        size: 38,
        paint: "https://example.test/livery_lite.webp",
      },
    });
  });

  it("gives the fallback the lite maps of the picked paint", () => {
    lowPower.value = false;
    paints.value = [
      {
        id: "red",
        name: "Red",
        media: {
          holoTexture: "https://example.test/red.webp",
          holoTextureLite: "https://example.test/red_lite.webp",
          holoTextureOrmLite: "https://example.test/red_orm_lite.webp",
        },
      } as unknown as ModelPaint,
    ];

    const { holoModel } = useModelHolo(model(textured), ModelStateEnum.FLIGHT, {
      textured: true,
      paintId: "red",
    });

    expect(holoModel.value?.fallback).toMatchObject({
      paint: "https://example.test/red_lite.webp",
      paintOrm: "https://example.test/red_orm_lite.webp",
    });
    paints.value = [];
  });

  it("has nothing to fall back to from the lite export", () => {
    lowPower.value = true;
    const { holoModel } = useModelHolo(model(textured), ModelStateEnum.FLIGHT, {
      textured: true,
    });

    expect(holoModel.value?.path).toBe(
      "https://example.test/textured_lite.glb",
    );
    expect(holoModel.value?.fallback).toBeUndefined();
  });

  it("has nothing to fall back to without a lite export", () => {
    lowPower.value = false;
    const { holoTexturedLite: _lite, ...media } = textured;
    const { holoModel } = useModelHolo(model(media), ModelStateEnum.FLIGHT, {
      textured: true,
    });

    expect(holoModel.value?.fallback).toBeUndefined();
  });

  it("gives the plain holo no fallback", () => {
    lowPower.value = false;
    const { holoModel } = useModelHolo(model(textured), ModelStateEnum.FLIGHT);

    expect(holoModel.value?.path).toBe("https://example.test/holo.glb");
    expect(holoModel.value?.fallback).toBeUndefined();
  });
});
