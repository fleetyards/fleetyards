import { flushPromises, mount } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import Component from "./index.vue";

const { enableFullscreen } = vi.hoisted(() => ({ enableFullscreen: vi.fn() }));

vi.mock("@/shared/composables/useMobile", () => ({
  useMobile: () => ref(false),
}));

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({ isFeatureEnabled: () => true }),
}));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useModelLoadoutPreview: () => ({
    data: ref({
      holoHull: { url: "https://example.test/hull.glb", size: 1000 },
      ports: [],
      items: [],
      servicingAreas: [
        {
          key: "int_body_rear.socpak#RepairZone",
          name: null,
          index: 1,
          position: [0, 0.8, 28.2],
          rotation: [0, 0, 0, 1],
          size: [12, 12, 14],
          width: 12,
          length: 14,
          height: 12,
        },
      ],
    }),
    isError: ref(false),
    isSuccess: ref(true),
  }),
}));

vi.mock("@/shared/components/HoloViewer/index.vue", () => ({
  __esModule: true,
  default: {
    name: "HoloViewer",
    props: {
      models: Array,
      inline: Boolean,
      contain: Boolean,
      controllable: { type: Boolean, default: true },
      zoomable: Boolean,
    },
    setup(_props: unknown, { expose }: { expose: (api: object) => void }) {
      expose({ enableFullscreen });
    },
    template: "<div />",
  },
}));

const mountStage = async () => {
  const wrapper = mount(Component, {
    props: { modelSlug: "golem-ox", variant: "stage" },
  });
  await flushPromises();

  return wrapper;
};

describe("LoadoutPreview", () => {
  it("shows the stage as the inline holo with its controls", async () => {
    const wrapper = await mountStage();
    const viewer = wrapper.findComponent({ name: "HoloViewer" });

    expect(viewer.props("inline")).toBe(true);
    expect(viewer.props("contain")).toBe(true);
    expect(viewer.props("controllable")).toBe(true);
    expect(viewer.props("zoomable")).toBe(false);
  });

  it("opens the stage's viewer full screen", async () => {
    const wrapper = await mountStage();

    (
      wrapper.vm as unknown as { enableFullscreen: () => void }
    ).enableFullscreen();

    expect(enableFullscreen).toHaveBeenCalled();
  });

  it("draws the servicing areas only when asked, with the pointed one picked out", async () => {
    const wrapper = mount(Component, {
      props: { modelSlug: "galaxy", variant: "backdrop" },
    });
    await flushPromises();

    const models = () =>
      wrapper.findComponent({ name: "HoloViewer" }).props("models") as {
        boxes?: unknown[];
      }[];

    expect(models()[0].boxes).toBeUndefined();
    expect(wrapper.emitted("servicingAreas")?.at(-1)?.[0]).toHaveLength(1);

    await wrapper.setProps({
      servicingAreas: true,
      highlightedArea: "int_body_rear.socpak#RepairZone",
    });

    expect(models()[0].boxes).toEqual([
      {
        id: "int_body_rear.socpak#RepairZone",
        position: [0, 0.8, 28.2],
        rotation: [0, 0, 0, 1],
        size: [12, 12, 14],
        highlighted: true,
      },
    ]);
  });
});
