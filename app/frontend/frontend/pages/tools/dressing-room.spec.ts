import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import {
  type ArmorSet,
  type CharacterBody,
  type Equipment,
  OutfitSlotEnum,
} from "@/services/fyApi";

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
  "painted-core": piece("painted-core", {
    holoRiggedMale: media("painted_core_rigged.glb"),
    holoRiggedTexturedMale: media("painted_core_rigged_textured.glb"),
  }),
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
  "pinned-pack": {
    ...piece("pinned-pack", { holo: media("pack.glb") }),
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

const GEAR: Record<string, Equipment> = {
  "gear-core": {
    ...piece("gear-core", { holoRiggedMale: media("gear_core_rigged.glb") }),
    fit: {
      type: "Char_Armor_Torso",
      ports: [
        {
          name: "grenade_attach_1",
          types: [{ type: "WeaponPersonal", subTypes: ["Grenade"] }],
          minSize: 1,
          maxSize: 1,
          bone: "grenade_attach_1_override",
          itemHelper: "attach_offset_left_01",
        },
        {
          name: "grenade_attach_2",
          types: [{ type: "WeaponPersonal", subTypes: ["Grenade"] }],
          minSize: 1,
          maxSize: 1,
        },
      ],
    },
  } as unknown as Equipment,
  "mk-4": {
    ...piece("mk-4", { holo: media("mk4.glb") }),
    subType: "Grenade",
    size: "1",
    fit: { type: "WeaponPersonal" },
    attachPoints: {
      attachOffsetLeft01: { position: [0, 0, 0.03], rotation: [0, 0, 0, 1] },
    },
  } as unknown as Equipment,
  "plain-grenade": {
    ...piece("plain-grenade", { holo: media("plain_grenade.glb") }),
    subType: "Grenade",
    size: "1",
    fit: { type: "WeaponPersonal" },
  } as unknown as Equipment,
  "small-pack": {
    ...piece("small-pack", {}),
    inventory: {
      capacity: 1000,
      dimensions: { x: 0.5, y: 1, z: 0.5 },
    },
  } as unknown as Equipment,
  medpen: {
    ...piece("medpen", {}),
    name: "MedPen",
    volume: 0.00018,
    volumeDimensions: { x: 0.03, y: 0.03, z: 0.1 },
  } as unknown as Equipment,
};

Object.assign(EQUIPMENT, GEAR);

const MALE: CharacterBody = {
  key: "male",
  holo: media("body.glb"),
  holoTextured: null,
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

const ARMOR_SETS: ArmorSet[] = [
  {
    name: "ADP Woodland",
    manufacturerName: "Clark Defense Systems",
    itemType: "heavy_armor",
    itemTypeLabel: "Heavy Armor",
    image: null,
    pieces: [
      { slot: OutfitSlotEnum.TORSO, slug: "adp-core", name: "ADP Core" },
      { slot: OutfitSlotEnum.LEGS, slug: "adp-legs", name: "ADP Legs" },
    ],
  },
];

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

const mount = async (
  query: Record<string, string> = {},
  { settle = true }: { settle?: boolean } = {},
) => {
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
  if (settle) await flushPromises();

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

  it("leaves a rifle undrawn on a backpack with no rig to bring the mount", async () => {
    const { wrapper } = await mount({
      primary: "p4-ar-hung",
      backpack: "pinned-pack",
    });

    expect(
      (viewerModel(wrapper).rig.attachments ?? []).filter(
        (attachment: { path: string }) => attachment.path === "/p4ar.glb",
      ),
    ).toEqual([]);
    expect(
      wrapper
        .find('[data-test="dressing-room-position-pending-primary"]')
        .exists(),
    ).toBe(true);
  });

  it("says so when the viewer leaves a weapon off for want of its mount", async () => {
    const { wrapper } = await mount({ primary: "p4-ar-hung" });
    const pending = () =>
      wrapper
        .find('[data-test="dressing-room-position-pending-primary"]')
        .exists();

    expect(pending()).toBe(false);

    wrapper
      .findComponent({ name: "HoloViewer" })
      .vm.$emit("unplaced", ["/p4ar.glb"]);
    await flushPromises();

    expect(pending()).toBe(true);
  });

  it("draws a piece from its painted rig, and from its plain rig once that fails", async () => {
    const { wrapper } = await mount({ torso: "painted-core" });

    expect(viewerModel(wrapper).rig.pieces).toEqual([
      {
        path: "/painted_core_rigged_textured.glb",
        size: 1000,
        textured: true,
        fallbackPath: "/painted_core_rigged.glb",
      },
    ]);

    wrapper
      .findComponent({ name: "HoloViewer" })
      .vm.$emit("fellBack", ["/painted_core_rigged_textured.glb"]);
    await flushPromises();

    expect(viewerModel(wrapper).rig.pieces).toEqual([
      { path: "/painted_core_rigged.glb", size: 1000 },
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

  it("draws the body with its skin, and in clay when that does not load", async () => {
    bodies.value = [{ ...MALE, holoTextured: media("body_textured.glb") }];

    const { wrapper } = await mount({ torso: "adp-core" });

    expect(viewerModel(wrapper)).toMatchObject({
      path: "/body_textured.glb",
      textured: true,
    });

    const viewer = wrapper.findComponent({ name: "HoloViewer" });
    viewer.vm.$emit("unavailable", "/body_textured.glb");
    viewer.vm.$emit("unavailable", "/body_textured.glb");
    await flushPromises();

    expect(viewerModel(wrapper)).toMatchObject({
      path: "/body.glb",
      textured: false,
    });
    expect(viewerModel(wrapper).rig).toBeDefined();

    bodies.value = [MALE];
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

  it("puts on an armour set, keeping the undersuit and weapons and taking off the rest of the old armour", async () => {
    const opened = vi.fn();
    const { useComlink } = await import("@/shared/composables/useComlink");
    const stop = useComlink().on("open-modal", opened);

    const { wrapper, router } = await mount({
      helmet: "old-helmet",
      torso: "painted-core",
      undersuit: "flight-suit",
      primary: "p4-ar",
    });

    await wrapper
      .find('[data-test="dressing-room-open-armor-sets"]')
      .trigger("click");

    const { props: modal } = opened.mock.calls[0]?.[0] as {
      props: { onSelect: (set: ArmorSet) => void };
    };
    modal.onSelect(ARMOR_SETS[0] as ArmorSet);
    await flushPromises();

    expect(router.currentRoute.value.query).toMatchObject({
      torso: "adp-core",
      legs: "adp-legs",
      undersuit: "flight-suit",
      primary: "p4-ar",
    });
    expect(router.currentRoute.value.query.helmet).toBeUndefined();

    stop();
  });

  it("picks a slot's piece from the modal", async () => {
    const opened = vi.fn();
    const { useComlink } = await import("@/shared/composables/useComlink");
    const stop = useComlink().on("open-modal", opened);

    const { wrapper, router } = await mount({ legs: "adp-legs" });

    await wrapper
      .find('[data-test="dressing-room-pick-torso"]')
      .trigger("click");

    const { props: modal } = opened.mock.calls[0]?.[0] as {
      props: { slot: string; onSelect: (item: Equipment) => void };
    };
    expect(modal.slot).toBe("torso");

    modal.onSelect(EQUIPMENT["adp-core"] as Equipment);
    await flushPromises();

    expect(router.currentRoute.value.query).toMatchObject({
      torso: "adp-core",
      legs: "adp-legs",
    });

    stop();
  });

  it("shows how to start with nothing to draw", async () => {
    bodies.value = [];

    const { wrapper } = await mount();

    expect(wrapper.find('[data-test="dressing-room-empty"]').exists()).toBe(
      true,
    );

    bodies.value = [MALE];
  });

  describe("gear slots", () => {
    it("asks for a worn piece while none offers gear", async () => {
      const { wrapper } = await mount();

      expect(
        wrapper.find('[data-test="dressing-room-gear-hint"]').exists(),
      ).toBe(true);
    });

    it("lays ammo, grenades and pens out in columns under the stage, and the rest with the other slots", async () => {
      const { wrapper } = await mount({ torso: "gear-core" });
      const columns = wrapper.find('[data-test="dressing-room-gear-columns"]');

      expect(
        columns.find('[data-test="dressing-room-slot-grenade_1"]').exists(),
      ).toBe(true);
      expect(
        columns
          .find('[data-test="dressing-room-pick-grenade_1"]')
          .attributes("aria-label"),
      ).toContain("Grenade 1");
      expect(
        wrapper.find('[data-test="dressing-room-gear-hint"]').exists(),
      ).toBe(false);
    });

    it("lists the gear columns after the armour and weapon slots", async () => {
      const { wrapper } = await mount({ torso: "gear-core" });
      const pieces = wrapper.find(".dressing-room__side--pieces").element;
      const columns = wrapper.find(
        '[data-test="dressing-room-gear-columns"]',
      ).element;

      expect(
        pieces.compareDocumentPosition(columns) &
          Node.DOCUMENT_POSITION_FOLLOWING,
      ).toBeTruthy();
    });

    it("says so when what is worn offers no gear at all", async () => {
      const { wrapper } = await mount({ undersuit: "flight-suit" });

      expect(
        wrapper.find('[data-test="dressing-room-gear-hint"]').text(),
      ).toContain("no gear slots");
    });

    it("marks nothing as wrong while the worn pieces are still loading", async () => {
      const { wrapper } = await mount(
        {
          torso: "gear-core",
          grenade_1: "mk-4",
          backpack: "small-pack",
          stored_backpack: "medpen",
        },
        { settle: false },
      );

      expect(
        wrapper.find('[data-test="dressing-room-fit-grenade_1"]').exists(),
      ).toBe(false);
      expect(
        wrapper
          .find('[data-test="dressing-room-storage-problem-backpack"]')
          .exists(),
      ).toBe(false);
      expect(
        wrapper.findComponent({ name: "DressingRoomOutfits" }).props("blocked"),
      ).toBe(false);
    });

    it("offers every port of what is worn, and hangs gear on its bone", async () => {
      const { wrapper } = await mount({
        torso: "gear-core",
        grenade_1: "mk-4",
      });

      expect(
        wrapper.find('[data-test="dressing-room-slot-grenade_1"]').text(),
      ).toContain("MK-4");
      expect(
        wrapper.find('[data-test="dressing-room-slot-grenade_2"]').exists(),
      ).toBe(true);
      expect(
        wrapper.find('[data-test="dressing-room-slot-grenade_3"]').exists(),
      ).toBe(false);

      expect(viewerModel(wrapper).rig.attachments).toContainEqual(
        expect.objectContaining({
          path: "/mk4.glb",
          bone: "grenade_attach_1_override",
          from: "/gear_core_rigged.glb",
          helper: { position: [0, 0, 0.03], rotation: [0, 0, 0, 1] },
        }),
      );
    });

    it("says so rather than guessing where gear without a helper goes", async () => {
      const { wrapper } = await mount({
        torso: "gear-core",
        grenade_1: "plain-grenade",
      });

      expect(
        wrapper
          .find('[data-test="dressing-room-position-pending-grenade_1"]')
          .exists(),
      ).toBe(true);
      expect(viewerModel(wrapper).rig.attachments ?? []).toEqual([]);
    });

    it("reports gear left without a port, and blocks saving it", async () => {
      const { wrapper } = await mount({ grenade_1: "mk-4" });

      expect(
        wrapper.find('[data-test="dressing-room-fit-grenade_1"]').exists(),
      ).toBe(true);
      expect(
        wrapper.findComponent({ name: "DressingRoomOutfits" }).props("blocked"),
      ).toBe(true);
    });
  });

  describe("worn storage", () => {
    it("shows no storage until a piece with room is worn", async () => {
      const { wrapper } = await mount({ torso: "gear-core" });

      expect(wrapper.find('[data-test="dressing-room-storage"]').exists()).toBe(
        false,
      );
    });

    it("lists what a piece holds and how much room it takes", async () => {
      const { wrapper } = await mount({
        backpack: "small-pack",
        stored_backpack: "medpen*3",
      });

      expect(
        wrapper
          .find('[data-test="dressing-room-stored-backpack-medpen"]')
          .text(),
      ).toContain("MedPen");
      expect(
        wrapper
          .find('[data-test="dressing-room-storage-space-backpack"]')
          .text(),
      ).toContain("540");
    });

    it("changes the quantity in the address, and stops at what fits", async () => {
      const { wrapper, router } = await mount({
        backpack: "small-pack",
        stored_backpack: "medpen*5",
      });

      const more = wrapper.find(
        '[data-test="dressing-room-stored-more-backpack-medpen"]',
      );
      expect(more.attributes("disabled")).toBeDefined();

      await wrapper
        .find('[data-test="dressing-room-stored-fewer-backpack-medpen"]')
        .trigger("click");
      await flushPromises();

      expect(router.currentRoute.value.query.stored_backpack).toBe("medpen*4");
    });

    it("keeps items whose piece came off, marked, and blocks saving them", async () => {
      const { wrapper } = await mount({ stored_backpack: "medpen" });

      expect(
        wrapper
          .find('[data-test="dressing-room-storage-problem-backpack"]')
          .exists(),
      ).toBe(true);
      expect(
        wrapper.findComponent({ name: "DressingRoomOutfits" }).props("blocked"),
      ).toBe(true);
    });

    it("loads a saved outfit's stored items into the address", async () => {
      const { wrapper, router } = await mount();

      wrapper.findComponent({ name: "DressingRoomOutfits" }).vm.$emit("load", {
        id: "saved",
        items: [{ slot: "backpack", equipment: GEAR["small-pack"] }],
        storedItems: [
          { holder: "backpack", quantity: 2, equipment: GEAR.medpen },
        ],
        heldWeapon: null,
        body: "male",
      });
      await flushPromises();

      expect(router.currentRoute.value.query.stored_backpack).toBe("medpen*2");
    });

    it("carries stored items in the share link", async () => {
      const { wrapper } = await mount({
        backpack: "small-pack",
        stored_backpack: "medpen*2",
      });

      await wrapper
        .find('[data-test="dressing-room-copy-link"]')
        .trigger("click");

      expect(copied.mock.lastCall?.[0]).toContain("stored_backpack=medpen*2");
    });
  });
});
