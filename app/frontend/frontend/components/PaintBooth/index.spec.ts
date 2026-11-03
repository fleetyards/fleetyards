import { describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type MediaFile, type Model, type ModelPaint } from "@/services/fyApi";
import { ModelStateEnum } from "@/frontend/composables/useModelStates";

vi.mock("@/shared/composables/useLowPowerDevice", () => ({
  isLowPowerDevice: () => false,
}));

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({ isFeatureEnabled: () => true }),
}));

const file = (name: string): MediaFile => ({
  name,
  contentType: "model/gltf-binary",
  size: 1000,
  url: `https://example.test/${name}`,
});

const paint = (slug: string, maps = true) =>
  ({
    id: `id-${slug}`,
    name: slug.toUpperCase(),
    slug,
    media: maps
      ? {
          holoTexture: `https://example.test/${slug}.ktx2`,
          holoTextureOrm: `https://example.test/${slug}_orm.ktx2`,
        }
      : {},
  }) as unknown as ModelPaint;

const paints = ref<ModelPaint[]>([
  paint("blue-steel"),
  paint("ghoulish-green"),
  paint("no-maps", false),
]);

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useModelPaints: () => ({ data: paints }),
}));

vi.mock("@/shared/components/HoloViewer/index.vue", () => ({
  default: {
    name: "HoloViewer",
    props: ["models"],
    emits: ["unavailable"],
    template: "<div data-test='holo-viewer' />",
  },
}));

const { default: PaintBooth } = await import("./index.vue");

const model = (media: Record<string, MediaFile>) =>
  ({
    slug: "gladius",
    name: "Gladius",
    media,
    metrics: { length: 20 },
  }) as unknown as Model;

const mount = async (
  props: { pose?: ModelStateEnum; paint?: string } = {},
  media: Record<string, MediaFile> = {
    holo: file("holo.glb"),
    holoTextured: file("textured.glb"),
    landedHoloTextured: file("landed_textured.glb"),
  },
) => {
  const wrapper = await mountWithDefaults(PaintBooth, {
    props: {
      model: model(media),
      pose: props.pose ?? ModelStateEnum.FLIGHT,
      paint: props.paint,
    },
  });
  await flushPromises();

  return wrapper;
};

const viewerModel = (wrapper: Awaited<ReturnType<typeof mount>>) =>
  wrapper.findComponent({ name: "HoloViewer" }).props("models")[0];

describe("PaintBooth", () => {
  it("shows the textured holo in its own colours and lists every paint with maps", async () => {
    const wrapper = await mount();

    expect(viewerModel(wrapper)).toMatchObject({
      path: "https://example.test/textured.glb",
      textured: true,
      paint: undefined,
    });
    expect(
      wrapper
        .findAll('[data-test^="paint-booth-paint-"]')
        .map((node) => node.attributes("data-test")),
    ).toEqual([
      "paint-booth-paint-own",
      "paint-booth-paint-blue-steel",
      "paint-booth-paint-ghoulish-green",
    ]);
    expect(
      wrapper
        .find('[data-test="paint-booth-paint-own"]')
        .attributes("aria-pressed"),
    ).toBe("true");
  });

  it("repaints the holo in the paint the address names", async () => {
    const wrapper = await mount({ paint: "ghoulish-green" });

    expect(viewerModel(wrapper)).toMatchObject({
      paint: "https://example.test/ghoulish-green.ktx2",
      paintOrm: "https://example.test/ghoulish-green_orm.ktx2",
    });
    expect(
      wrapper
        .find('[data-test="paint-booth-paint-ghoulish-green"]')
        .attributes("aria-pressed"),
    ).toBe("true");
  });

  it("asks for a paint by its slug, and for the own colours by none", async () => {
    const wrapper = await mount({ paint: "blue-steel" });

    await wrapper
      .find('[data-test="paint-booth-paint-ghoulish-green"]')
      .trigger("click");
    await wrapper.find('[data-test="paint-booth-paint-own"]').trigger("click");

    expect(wrapper.emitted("update:paint")).toEqual([
      ["ghoulish-green"],
      [undefined],
    ]);
  });

  it("offers the poses with a textured export and shows the landed one", async () => {
    const wrapper = await mount({ pose: ModelStateEnum.LANDED });

    expect(viewerModel(wrapper).path).toBe(
      "https://example.test/landed_textured.glb",
    );

    await wrapper
      .find(`[data-test="paint-booth-pose-${ModelStateEnum.FLIGHT}"]`)
      .trigger("click");

    expect(wrapper.emitted("update:pose")).toEqual([[ModelStateEnum.FLIGHT]]);
  });

  it("leaves the pose switch out for a ship painted in one pose only", async () => {
    const wrapper = await mount(
      { pose: ModelStateEnum.LANDED },
      { holo: file("holo.glb"), holoTextured: file("textured.glb") },
    );

    expect(wrapper.find('[data-test="paint-booth-poses"]').exists()).toBe(
      false,
    );
    expect(viewerModel(wrapper).path).toBe("https://example.test/textured.glb");
  });

  it("falls back to the plain holo and hides the paints when the textured one fails", async () => {
    const wrapper = await mount();

    wrapper.findComponent({ name: "HoloViewer" }).vm.$emit("unavailable");
    await flushPromises();

    expect(viewerModel(wrapper)).toMatchObject({
      path: "https://example.test/holo.glb",
      textured: false,
    });
    expect(wrapper.find('[data-test="paint-booth-unavailable"]').exists()).toBe(
      true,
    );
    expect(wrapper.find('[data-test="paint-booth-paints"]').exists()).toBe(
      false,
    );
  });
});
