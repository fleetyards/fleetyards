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
    holoRiggedMale: media("core_rigged.glb"),
  }),
  "adp-legs": piece("adp-legs", { holo: media("legs.glb") }),
  "pembroke-backpack": piece("pembroke-backpack", {}),
  "p4-ar": piece("p4-ar", {
    holo: media("p4ar.glb"),
    holoTextured: media("p4ar_textured.glb"),
  }),
  "s-38": piece("s-38", { holo: media("s38.glb") }),
};

const MALE: CharacterBody = {
  key: "male",
  holo: media("body.glb"),
  animations: media("animations.glb"),
  clips: [
    { name: "shop_pose_01", static: true, looping: false },
    { name: "idle_stand", static: false, looping: true },
  ],
};

const bodies = ref<CharacterBody[]>([MALE]);

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  getEquipmentItemQueryOptions: (
    slug: string,
    options?: { query?: Record<string, unknown> },
  ) => ({
    ...options?.query,
    queryKey: ["equipment-item", slug],
    queryFn: () =>
      EQUIPMENT[slug]
        ? Promise.resolve(EQUIPMENT[slug])
        : Promise.reject(new Error("not found")),
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
  it("dresses the body in the rigged pieces the address names, standing idle", async () => {
    const { wrapper } = await mount({ torso: "adp-core", legs: "adp-legs" });

    expect(
      wrapper.find('[data-test="dressing-room-slot-torso"]').text(),
    ).toContain("ADP-CORE");

    const model = viewerModel(wrapper);
    expect(model.path).toBe("/body.glb");
    expect(model.rig).toEqual({
      pieces: [{ path: "/core_rigged.glb", size: 1000 }],
      animations: "/animations.glb",
      clip: "idle_stand",
      pedestal: true,
    });
    expect(
      wrapper.find('[data-test="dressing-room-no-holo-legs"]').exists(),
    ).toBe(true);
  });

  it("stows the weapons on the bones the armour brings, and puts the held one in hand", async () => {
    const { wrapper } = await mount({
      torso: "adp-core",
      primary: "p4-ar",
      sidearm: "s-38",
      held: "sidearm",
    });

    expect(viewerModel(wrapper).rig.attachments).toEqual([
      {
        path: "/p4ar_textured.glb",
        bone: "wep_stocked_attach_2_override",
        size: 1000,
        textured: true,
        fallbackPath: "/p4ar.glb",
      },
      {
        path: "/s38.glb",
        bone: "RightWeaponBone",
        size: 1000,
        textured: false,
        fallbackPath: undefined,
      },
    ]);
  });

  it("takes a weapon out of hand when it is held again", async () => {
    const { wrapper, router } = await mount({
      sidearm: "s-38",
      held: "sidearm",
    });

    await wrapper
      .find('[data-test="dressing-room-hold-sidearm"]')
      .trigger("click");
    await flushPromises();

    expect(router.currentRoute.value.query.held).toBeUndefined();
  });

  it("drops the weapon in hand with the weapon", async () => {
    const { wrapper, router } = await mount({
      sidearm: "s-38",
      held: "sidearm",
    });

    await wrapper
      .find('[data-test="dressing-room-clear-sidearm"]')
      .trigger("click");
    await flushPromises();

    expect(router.currentRoute.value.query.held).toBeUndefined();
  });

  it("poses the body as the address says", async () => {
    const { wrapper } = await mount({
      torso: "adp-core",
      pose: "shop_pose_01",
    });

    expect(viewerModel(wrapper).rig.clip).toBe("shop_pose_01");
  });

  it("mounts the static pieces, painted where it can, while no body is exported", async () => {
    bodies.value = [];

    const { wrapper } = await mount({ torso: "adp-core", legs: "adp-legs" });

    const model = viewerModel(wrapper);
    expect(model.path).toBe("/legs.glb");
    expect(
      model.mounts.map((mount: { path: string; textured: boolean }) => [
        mount.path,
        mount.textured,
      ]),
    ).toEqual([["/core_textured.glb", true]]);

    bodies.value = [MALE];
  });

  it("lists a piece without a holo and says it is not drawn", async () => {
    const { wrapper } = await mount({ backpack: "pembroke-backpack" });

    expect(
      wrapper.find('[data-test="dressing-room-no-holo-backpack"]').exists(),
    ).toBe(true);
    expect(viewerModel(wrapper).rig.pieces).toEqual([]);
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

  it("draws the pieces on their own when the body does not load", async () => {
    const { wrapper } = await mount({ legs: "adp-legs" });

    wrapper.findComponent({ name: "HoloViewer" }).vm.$emit("unavailable");
    await flushPromises();

    expect(viewerModel(wrapper).path).toBe("/legs.glb");
  });

  it("holds off saving while the address names a piece the catalogue lacks", async () => {
    const { wrapper } = await mount({
      torso: "adp-core",
      legs: "retired-legs",
    });

    expect(
      wrapper.find('[data-test="dressing-room-slot-legs"]').text(),
    ).toContain("Item not found");
    expect(
      wrapper.findComponent({ name: "DressingRoomOutfits" }).props("pending"),
    ).toBe(true);
  });

  it("shows how to start with nothing to draw", async () => {
    bodies.value = [];

    const { wrapper } = await mount();

    expect(wrapper.find('[data-test="dressing-room-empty"]').exists()).toBe(
      true,
    );

    bodies.value = [MALE];
  });
});
