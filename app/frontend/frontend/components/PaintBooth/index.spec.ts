import { beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type MediaFile, type Model, type ModelPaint } from "@/services/fyApi";

// The cards carry a lazy background image, and jsdom has no IntersectionObserver.
// Per test, since a spec sharing this worker can unstub globals between them.
beforeEach(() => {
  vi.stubGlobal(
    "IntersectionObserver",
    class {
      observe() {}
      unobserve() {}
      disconnect() {}
    },
  );
});

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
  props: { paint?: string } = {},
  media: Record<string, MediaFile> = {
    holo: file("holo.glb"),
    landedHolo: file("landed_holo.glb"),
    holoTextured: file("textured.glb"),
    landedHoloTextured: file("landed_textured.glb"),
  },
) => {
  const wrapper = await mountWithDefaults(PaintBooth, {
    props: {
      model: model(media),
      paint: props.paint,
    },
  });
  await flushPromises();

  return wrapper;
};

const viewerModel = (wrapper: Awaited<ReturnType<typeof mount>>) =>
  wrapper.findComponent({ name: "HoloViewer" }).props("models")[0];

describe("PaintBooth", () => {
  it("stands the landed textured holo in its own colours, with every paint with maps", async () => {
    const wrapper = await mount();

    expect(viewerModel(wrapper)).toMatchObject({
      path: "https://example.test/landed_textured.glb",
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
        .find('[data-test="paint-booth-paint-own"] button')
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
        .find('[data-test="paint-booth-paint-ghoulish-green"] button')
        .attributes("aria-pressed"),
    ).toBe("true");
  });

  it("asks for a paint by its slug, and for the own colours by none", async () => {
    const wrapper = await mount({ paint: "blue-steel" });

    await wrapper
      .find('[data-test="paint-booth-paint-ghoulish-green"] button')
      .trigger("click");
    await wrapper
      .find('[data-test="paint-booth-paint-own"] button')
      .trigger("click");

    expect(wrapper.emitted("update:paint")).toEqual([
      ["ghoulish-green"],
      [undefined],
    ]);
  });

  it("shows the flying holo for a ship painted only in flight", async () => {
    const wrapper = await mount(
      {},
      { holo: file("holo.glb"), holoTextured: file("textured.glb") },
    );

    expect(viewerModel(wrapper).path).toBe("https://example.test/textured.glb");
  });

  it("falls back to the plain holo and hides the paints when the textured one fails", async () => {
    const wrapper = await mount();

    wrapper.findComponent({ name: "HoloViewer" }).vm.$emit("unavailable");
    await flushPromises();

    expect(viewerModel(wrapper)).toMatchObject({
      path: "https://example.test/landed_holo.glb",
      textured: false,
    });
    expect(wrapper.find('[data-test="paint-booth-unavailable"]').exists()).toBe(
      true,
    );
    expect(wrapper.find('[data-test="paint-booth-paints"]').exists()).toBe(
      false,
    );
  });
  it("says so for a ship without a textured export", async () => {
    const wrapper = await mount({}, { holo: file("holo.glb") });

    expect(viewerModel(wrapper).textured).toBe(false);
    expect(wrapper.find('[data-test="paint-booth-unavailable"]').exists()).toBe(
      true,
    );
  });
  it("says so on the stage when a ship without a plain holo fails to draw", async () => {
    const wrapper = await mount(
      {},
      { landedHoloTextured: file("landed_textured.glb") },
    );

    wrapper.findComponent({ name: "HoloViewer" }).vm.$emit("unavailable");
    await flushPromises();

    expect(wrapper.findComponent({ name: "HoloViewer" }).exists()).toBe(false);
    expect(wrapper.find('[data-test="paint-booth-no-holo"]').exists()).toBe(
      true,
    );
    expect(wrapper.find('[data-test="paint-booth-fullscreen"]').exists()).toBe(
      false,
    );
  });
});
