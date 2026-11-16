import { flushPromises, mount } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import Component from "./index.vue";

const { enableFullscreen } = vi.hoisted(() => ({ enableFullscreen: vi.fn() }));

vi.mock("@/shared/composables/useMobile", () => ({
  useMobile: () => ref(false),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    toNumber: (value: number) => String(value),
  }),
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
      moduleHulls: [],
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
      cargoGrids: [
        {
          name: "hardpoint_cargogrid",
          port: null,
          parentPort: null,
          position: [0, 1, 2],
          rotation: [0, 0, 0, 1],
          size: [2.5, 2.5, 10],
          scu: 32,
          stripped: false,
        },
      ],
      doors: [
        {
          id: "hardpoint_door_rear",
          kind: "hatch",
          position: [0, 0, 10],
          durationS: 3,
          bounds: null,
          outline: null,
          outlineNodes: [],
          exterior: true,
          parts: [],
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
    emits: ["mountPoint", "cargoPoint"],
    setup(_props: unknown, { expose }: { expose: (api: object) => void }) {
      expose({ enableFullscreen });
    },
    template: "<div><slot /></div>",
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
  it("names the pointed part and says a click changes it, where it can", async () => {
    const wrapper = mount(Component, {
      props: {
        modelSlug: "gladius",
        variant: "backdrop",
        interactive: true,
        pickable: true,
        slots: [
          {
            name: "hardpoint_gun",
            path: "hardpoint_gun",
            part: { name: "Gun", size: "3" },
            changeable: true,
            slots: [],
          },
          {
            name: "hardpoint_relay",
            path: "hardpoint_relay",
            part: { name: "Relay" },
            changeable: false,
            slots: [],
          },
        ],
      },
    });
    await flushPromises();

    const viewer = wrapper.findComponent({ name: "HoloViewer" });
    const card = () => wrapper.find('[data-test="loadout-preview-card"]');

    viewer.vm.$emit("mountPoint", "hardpoint_gun");
    await flushPromises();
    expect(card().text()).toContain("Gun");
    expect(card().text()).toContain("actions.holoViewer.part");
    expect(wrapper.emitted("point")?.at(-1)).toEqual(["hardpoint_gun"]);

    viewer.vm.$emit("mountPoint", "hardpoint_relay");
    await flushPromises();
    expect(card().text()).toContain("Relay");
    expect(card().text()).not.toContain("actions.holoViewer.part");

    viewer.vm.$emit("mountPoint", undefined);
    viewer.vm.$emit("cargoPoint", "hardpoint_cargogrid");
    await flushPromises();
    expect(card().text()).toContain("32 SCU");
  });

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
        layers?: { boxes?: boolean };
      }[];

    // Kept while hidden, so turning them off fades them out.
    expect(models()[0].layers?.boxes).toBe(false);
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
    expect(models()[0].layers?.boxes).toBe(true);
  });

  it("offers the cargo grids and doors, shown and opened when asked", async () => {
    const wrapper = mount(Component, {
      props: { modelSlug: "caterpillar", variant: "backdrop" },
    });
    await flushPromises();

    const model = () =>
      (
        wrapper.findComponent({ name: "HoloViewer" }).props("models") as {
          cargoGrids: { id: string }[];
          openDoors: string[];
          layers: { cargo?: boolean };
        }[]
      )[0];

    expect(wrapper.emitted("overlays")?.at(-1)?.[0]).toEqual({
      cargoGrids: true,
      doors: true,
    });
    expect(model().cargoGrids.map((grid) => grid.id)).toEqual([
      "hardpoint_cargogrid",
    ]);
    expect(model().layers.cargo).toBe(false);
    expect(model().openDoors).toEqual([]);

    await wrapper.setProps({ cargoGrids: true, doorsOpen: true });

    expect(model().layers.cargo).toBe(true);
    expect(model().openDoors).toEqual(["hardpoint_door_rear"]);
  });
});
