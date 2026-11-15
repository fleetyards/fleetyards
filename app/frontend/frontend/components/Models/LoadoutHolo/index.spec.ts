import { describe, expect, it, vi } from "vitest";
import { createRouter, createMemoryHistory } from "vue-router";
import {
  HullItemKindEnum,
  type LoadoutSlot,
  type ModelLoadoutPreview,
  type ModelLoadoutPreviewPort,
} from "@/services/fyApi";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import Component from "./index.vue";

const port = (
  name: string,
  overrides: Partial<ModelLoadoutPreviewPort> = {},
): ModelLoadoutPreviewPort => ({
  name,
  parent: null,
  helper: true,
  position: [0, 0, 0],
  rotation: [0, 0, 0, 1],
  flags: "",
  editable: false,
  types: [],
  defaultItem: null,
  geometry: true,
  stripped: false,
  inParentHolo: false,
  hullNode: name,
  itemKind: HullItemKindEnum.OTHER,
  ...overrides,
});

const preview: ModelLoadoutPreview = {
  holoHull: {
    name: "flight_holo_hull.glb",
    url: "https://example.test/hull.glb",
    size: 1000,
  },
  ports: [
    port("hardpoint_mining_laser", {
      itemKind: HullItemKindEnum.WEAPON,
      defaultItem: "mount_gimbal_mining",
    }),
    port("hardpoint_thruster_main", { itemKind: HullItemKindEnum.THRUSTER }),
    port("hardpoint_stored_pod_1", {
      defaultItem: "cargo_shipmining_pod_prospector_collapsed",
    }),
  ],
  items: [],
  servicingAreas: [],
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
      parts: [],
    },
  ],
};

const slots: LoadoutSlot[] = [
  {
    name: "hardpoint_mining_laser",
    hardpointId: "hardpoint_mining_laser",
    types: [],
    editable: false,
    slots: [],
    stock: { id: "laser", name: "Arbor MH1", slug: "arbor-mh1", size: "1" },
  },
];

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useModelLoadoutPreview: () => ({ data: ref(preview) }),
  useModelLoadoutSlots: () => ({ data: ref(slots) }),
}));

vi.mock("@/shared/components/HoloViewer/index.vue", () => ({
  __esModule: true,
  default: {
    name: "HoloViewer",
    props: { models: Array },
    emits: ["builtInPoint", "builtInSelect", "doorPoint", "doorSelect"],
    template: '<div><slot name="actions" /><slot /></div>',
  },
}));

const mountHolo = async () => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: "/", name: "home", component: { template: "<div />" } },
      {
        path: "/components/:slug",
        name: "component",
        component: { template: "<div />" },
      },
    ],
  });
  const push = vi.spyOn(router, "push");

  const wrapper = await mountWithDefaults(Component, {
    props: { modelSlug: "prospector" },
    plugins: [router],
  });

  const viewer = () => wrapper.findComponent({ name: "HoloViewer" });
  const model = () =>
    (
      viewer().props("models") as {
        builtIns: { id: string }[];
        openDoors: string[];
        layers: { cargo?: boolean };
      }[]
    )[0];

  return { wrapper, viewer, model, push };
};

describe("ModelLoadoutHolo", () => {
  it("picks out the fixed weapons and mining bags, not the thrusters", async () => {
    const { model } = await mountHolo();

    expect(model().builtIns.map((builtIn) => builtIn.id)).toEqual([
      "hardpoint_mining_laser",
      "hardpoint_stored_pod_1",
    ]);
  });

  it("names a pointed mining bag", async () => {
    const { wrapper, viewer } = await mountHolo();

    viewer().vm.$emit("builtInPoint", "hardpoint_stored_pod_1");
    await nextTick();

    expect(
      wrapper.find('[data-test="model-loadout-holo-card"]').text(),
    ).toContain("Mining bag");
  });

  it("names a pointed built-in item and opens its page on a click", async () => {
    const { wrapper, viewer, push } = await mountHolo();

    viewer().vm.$emit("builtInPoint", "hardpoint_mining_laser");
    await nextTick();

    const card = wrapper.find('[data-test="model-loadout-holo-card"]');
    expect(card.text()).toContain("Arbor MH1");
    expect(card.text()).toContain("Weapon");

    viewer().vm.$emit("builtInSelect", "hardpoint_mining_laser");

    expect(push).toHaveBeenCalledWith({
      name: "component",
      params: { slug: "arbor-mh1" },
    });
  });

  it("hides the cargo grids and opens the doors from its buttons", async () => {
    const { wrapper, model } = await mountHolo();

    expect(model().layers.cargo).toBe(true);
    expect(model().openDoors).toEqual([]);

    await wrapper
      .find('[data-test="model-loadout-holo-cargo-grids"]')
      .trigger("click");
    await wrapper
      .find('[data-test="model-loadout-holo-doors"]')
      .trigger("click");

    expect(model().layers.cargo).toBe(false);
    expect(model().openDoors).toEqual(["hardpoint_door_rear"]);
  });

  it("opens one door on a click and says which way it goes", async () => {
    const { wrapper, viewer, model } = await mountHolo();

    viewer().vm.$emit("doorPoint", "hardpoint_door_rear");
    await nextTick();
    const card = () => wrapper.find('[data-test="model-loadout-holo-card"]');
    expect(card().text()).toContain("Hatch");
    expect(card().text()).toContain("Click to open");

    viewer().vm.$emit("doorSelect", "hardpoint_door_rear");
    await nextTick();

    expect(model().openDoors).toEqual(["hardpoint_door_rear"]);
    expect(card().text()).toContain("Click to close");
  });
});
