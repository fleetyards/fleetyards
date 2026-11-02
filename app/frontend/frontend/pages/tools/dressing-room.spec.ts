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
  "p4-ar-hung": {
    ...piece("p4-ar-hung", { holo: media("p4ar.glb") }),
    attachPoints: {
      attachOffsetLeft01: {
        position: [0, 0.1, -0.2],
        rotation: [0, 0, 0, 1],
      },
    },
  } as unknown as Equipment,
  "s-38": piece("s-38", { holo: media("s38.glb") }),
  "crusader-pack": {
    ...piece("crusader-pack", { holoRiggedMale: media("pack_rigged.glb") }),
    fit: {
      type: "Char_Armor_Backpack",
      ports: [
        {
          name: "wep_stocked_3",
          types: [{ type: "WeaponPersonal", subTypes: ["Medium", "Large"] }],
          minSize: 2,
          maxSize: 5,
        },
      ],
    },
  } as unknown as Equipment,
  "flight-suit": {
    ...piece("flight-suit", {}),
    name: "Flight Suit",
    fit: {
      type: "Char_Armor_Undersuit",
      ports: [
        {
          name: "Armor_Helmet",
          types: [{ type: "Char_Armor_Helmet" }],
          minSize: 1,
          maxSize: 1,
        },
      ],
    },
  } as unknown as Equipment,
};

const MALE: CharacterBody = {
  key: "male",
  holo: media("body.glb"),
  animations: media("animations.glb"),
  weaponInHand: null,
  lighting: [],
  clips: [
    { name: "shop_pose_01", static: true, looping: false },
    { name: "idle_stand", static: false, looping: true },
    { name: "hold_rifle_lowered", static: false, looping: true },
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

const copied = vi.fn((_text: string) => Promise.resolve());

vi.mock("@/shared/utils/CopyText", () => ({
  default: (text: string) => copied(text),
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
      cover: ["torso"],
    });
    expect(
      wrapper.find('[data-test="dressing-room-no-holo-legs"]').exists(),
    ).toBe(true);
  });

  it("puts the held weapon in hand, and waits for a stowed one's helper", async () => {
    const { wrapper } = await mount({
      torso: "adp-core",
      primary: "p4-ar",
      sidearm: "s-38",
      held: "sidearm",
    });

    expect(viewerModel(wrapper).rig.attachments).toEqual([
      {
        path: "/s38.glb",
        bone: "RightWeaponBone",
        size: 1000,
        textured: false,
        fallbackPath: undefined,
        helper: undefined,
      },
    ]);
    expect(
      wrapper
        .find('[data-test="dressing-room-position-pending-primary"]')
        .exists(),
    ).toBe(true);
  });

  it("hangs a stowed weapon by the helper the export lists", async () => {
    const { wrapper } = await mount({ primary: "p4-ar-hung" });

    expect(viewerModel(wrapper).rig.attachments).toEqual([
      {
        path: "/p4ar.glb",
        bone: "wep_stocked_attach_3_override",
        size: 1000,
        textured: false,
        fallbackPath: undefined,
        helper: { position: [0, 0.1, -0.2], rotation: [0, 0, 0, 1] },
      },
    ]);
  });

  it("hangs a rifle from the worn backpack's own mount", async () => {
    const { wrapper } = await mount({
      primary: "p4-ar-hung",
      backpack: "crusader-pack",
    });

    expect(viewerModel(wrapper).rig.attachments).toEqual([
      expect.objectContaining({
        path: "/p4ar.glb",
        bone: "wep_stocked_attach_3_override",
        from: "/pack_rigged.glb",
      }),
    ]);
  });

  it("switches the body and keeps it in the address", async () => {
    bodies.value = [
      MALE,
      { ...MALE, key: "female", holo: media("female.glb") },
    ];

    const { wrapper, router } = await mount({ torso: "adp-core" });

    await wrapper
      .find('[data-test="dressing-room-body-female"]')
      .trigger("click");
    await flushPromises();

    expect(router.currentRoute.value.query.body).toBe("female");
    expect(viewerModel(wrapper).path).toBe("/female.glb");
    expect(viewerModel(wrapper).rig.pieces).toEqual([]);

    bodies.value = [MALE];
  });

  it("holds a rifle in the body's weapon hand, turned as the export says, and in the rifle pose", async () => {
    bodies.value = [
      {
        ...MALE,
        weaponInHand: {
          bones: { right: "RightWeaponBone", left: "LeftWeaponBone" },
          helper: {
            position: [0, 0, 0],
            rotation: [-0.707107, 0, 0, 0.707107],
          },
        },
      },
    ];

    const { wrapper } = await mount({ primary: "p4-ar", held: "primary" });

    const rig = viewerModel(wrapper).rig;
    expect(rig.clip).toBe("hold_rifle_lowered");
    expect(rig.attachments[0]).toMatchObject({
      bone: "RightWeaponBone",
      helper: { position: [0, 0, 0], rotation: [-0.707107, 0, 0, 0.707107] },
    });

    bodies.value = [MALE];
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
    expect(model.path).toBe("/core_textured.glb");
    expect(
      model.mounts.map((mount: { path: string; textured: boolean }) => [
        mount.path,
        mount.textured,
      ]),
    ).toEqual([["/legs.glb", false]]);

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

  it("shares the body, the pose and the weapon in hand with the outfit", async () => {
    bodies.value = [
      MALE,
      { ...MALE, key: "female", holo: media("female.glb") },
    ];

    const { wrapper } = await mount({
      sidearm: "s-38",
      held: "sidearm",
      pose: "shop_pose_01",
      body: "female",
      outfit: "mine",
    });

    await wrapper
      .find('[data-test="dressing-room-copy-link"]')
      .trigger("click");

    const shared = new URL(copied.mock.calls[0][0].replace("#", ""));
    expect(Object.fromEntries(shared.searchParams)).toEqual({
      sidearm: "s-38",
      held: "sidearm",
      pose: "shop_pose_01",
      body: "female",
    });

    bodies.value = [MALE];
  });

  it("closes the slots the undersuit offers no port for", async () => {
    const { wrapper } = await mount({ undersuit: "flight-suit" });

    expect(
      wrapper.find('[data-test="dressing-room-fit-arms"]').text(),
    ).toContain("Flight Suit has no slot for this");
    expect(
      wrapper
        .find('[data-test="dressing-room-pick-arms"]')
        .attributes("disabled"),
    ).toBeDefined();
    expect(
      wrapper.find('[data-test="dressing-room-fit-helmet"]').exists(),
    ).toBe(false);
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
