import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { type CharacterBody, type Equipment } from "@/services/fyApi";

const media = (name: string) => ({
  url: `/${name}`,
  name,
  contentType: "model/gltf-binary",
  size: 1000,
});

const piece = (slug: string, holos: Record<string, unknown>) =>
  ({
    id: `id-${slug}`,
    name: slug.toUpperCase(),
    slug,
    media: holos,
  }) as unknown as Equipment;

const EQUIPMENT: Record<string, Equipment> = {
  "adp-core": piece("adp-core", {
    holo: media("core.glb"),
    holoTextured: media("core_textured.glb"),
  }),
  "adp-legs": piece("adp-legs", { holo: media("legs.glb") }),
  "pembroke-backpack": piece("pembroke-backpack", {}),
};

const bodies = ref<CharacterBody[]>([{ key: "male", holo: media("body.glb") }]);

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  getEquipmentItemQueryOptions: (slug: string) => ({
    queryKey: ["equipment-item", slug],
    queryFn: () => Promise.resolve(EQUIPMENT[slug]),
  }),
  useCharacterBodies: () => ({ data: bodies }),
}));

vi.mock("@/shared/components/HoloViewer/index.vue", () => ({
  default: {
    name: "HoloViewer",
    props: ["models"],
    template: "<div data-test='holo-viewer' />",
  },
}));

const { default: Component } = await import("./dressing-room.vue");

const mount = async (query: Record<string, string> = {}) => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      {
        path: "/tools/dressing-room/",
        name: "dressing-room",
        component: { template: "<div />" },
        meta: { title: "tools.dressingRoom" },
      },
      {
        path: "/equipment/:slug/",
        name: "equipment-item",
        component: { template: "<div />" },
      },
    ],
  });
  await router.push({ name: "dressing-room", query });

  const wrapper = await mountWithDefaults<typeof Component>(Component, {
    plugins: [router],
  });
  await flushPromises();

  return { wrapper, router };
};

const viewerModel = (wrapper: Awaited<ReturnType<typeof mount>>["wrapper"]) =>
  wrapper.findComponent({ name: "HoloViewer" }).props("models")[0];

describe("ToolsDressingRoomPage", () => {
  it("dresses the body in the pieces the address names, painted where it can", async () => {
    const { wrapper } = await mount({ torso: "adp-core", legs: "adp-legs" });

    expect(
      wrapper.find('[data-test="dressing-room-slot-torso"]').text(),
    ).toContain("ADP-CORE");

    const model = viewerModel(wrapper);
    expect(model.path).toBe("/body.glb");
    expect(model.frameMounts).toBe(true);
    expect(
      model.mounts.map((mount: { path: string; textured: boolean }) => [
        mount.path,
        mount.textured,
      ]),
    ).toEqual([
      ["/legs.glb", false],
      ["/core_textured.glb", true],
    ]);
  });

  it("lists a piece without a holo and says it is not drawn", async () => {
    const { wrapper } = await mount({ backpack: "pembroke-backpack" });

    expect(
      wrapper.find('[data-test="dressing-room-no-holo-backpack"]').exists(),
    ).toBe(true);
    expect(viewerModel(wrapper).mounts).toEqual([]);
  });

  it("empties a slot from the address", async () => {
    const { wrapper, router } = await mount({
      torso: "adp-core",
      legs: "adp-legs",
    });

    await wrapper
      .find('[data-test="dressing-room-clear-legs"]')
      .trigger("click");
    await flushPromises();

    expect(router.currentRoute.value.query).toMatchObject({
      torso: "adp-core",
    });
    expect(router.currentRoute.value.query.legs).toBeUndefined();
  });

  it("roots the figure on a piece while no body is exported", async () => {
    bodies.value = [];

    const { wrapper } = await mount({ legs: "adp-legs" });

    expect(viewerModel(wrapper).path).toBe("/legs.glb");

    bodies.value = [{ key: "male", holo: media("body.glb") }];
  });

  it("draws the pieces on their own when the body does not load", async () => {
    const { wrapper } = await mount({ legs: "adp-legs" });

    wrapper.findComponent({ name: "HoloViewer" }).vm.$emit("unavailable");
    await flushPromises();

    expect(viewerModel(wrapper).path).toBe("/legs.glb");
  });

  it("shows how to start with nothing to draw", async () => {
    bodies.value = [];

    const { wrapper } = await mount();

    expect(wrapper.find('[data-test="dressing-room-empty"]').exists()).toBe(
      true,
    );

    bodies.value = [{ key: "male", holo: media("body.glb") }];
  });
});
