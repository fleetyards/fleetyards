import { describe, expect, it } from "vitest";
import {
  HardpointCategoryEnum,
  HullItemKindEnum,
  type LoadoutSlot,
  type ModelLoadoutPreview,
  type ModelLoadoutPreviewPort,
} from "@/services/fyApi";
import {
  builtInHighlights,
  categoryColor,
  loadoutCargoGrids,
  loadoutMounts,
  portTree,
  previewSlotsFromLoadout,
  TAB_COLORS,
} from "./loadoutPreview";

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
  editable: true,
  types: [],
  defaultItem: null,
  geometry: true,
  stripped: false,
  inParentHolo: false,
  hullNode: null,
  defaultItemName: null,
  defaultItemSlug: null,
  itemKind: null,
  ...overrides,
});

const slot = (
  name: string,
  overrides: Partial<LoadoutSlot> = {},
): LoadoutSlot => ({
  name,
  hardpointId: name,
  types: [],
  editable: true,
  slots: [],
  ...overrides,
});

const holo = (scKey: string) => `https://example.com/${scKey}/holo.glb`;

// The Gladius nose: a gimbal holding a gatling whose barrel is part of the
// gatling's holo, two racks that each name their missile ports alike, and a
// relay that stays in the hull.
const preview: ModelLoadoutPreview = {
  ports: [
    port("hardpoint_gun_nose", {
      position: [0, -1.17, -10.59],
      defaultItem: "mount_gimbal_s3",
      stripped: true,
    }),
    port("hardpoint_class_2", {
      parent: "hardpoint_gun_nose",
      position: [0, -0.14, 0],
      defaultItem: "gats_ballisticgatling_s3",
      stripped: true,
    }),
    port("BAR1", {
      parent: "hardpoint_class_2",
      defaultItem: "gats_ballisticgatling_barrel_s3",
      inParentHolo: true,
    }),
    port("hardpoint_missilerack_left", {
      defaultItem: "mrck_s03_behr_dual_s02",
      stripped: true,
    }),
    port("missile_01_attach", {
      parent: "hardpoint_missilerack_left",
      position: [1, 0, 0],
      defaultItem: "misl_s02_ir_fski_ignite",
      stripped: true,
    }),
    port("hardpoint_missilerack_right", {
      defaultItem: "mrck_s03_behr_dual_s02",
      stripped: true,
    }),
    port("missile_01_attach", {
      parent: "hardpoint_missilerack_right",
      position: [2, 0, 0],
      defaultItem: "misl_s02_ir_fski_ignite",
      stripped: true,
    }),
    port("hardpoint_relay", { defaultItem: "relay_3slot" }),
    port("$slot_fuse_01", {
      parent: "hardpoint_relay",
      defaultItem: "fuse_subitem_standard",
      inParentHolo: true,
    }),
  ],
  items: [
    "mount_gimbal_s3",
    "gats_ballisticgatling_s3",
    "mrck_s03_behr_dual_s02",
    "misl_s02_ir_fski_ignite",
  ].map((scKey) => ({ scKey, holoUrl: holo(scKey) })),
  servicingAreas: [],
  cargoGrids: [],
  doors: [],
};

describe("portTree", () => {
  it("hangs each nested port off the last port named as its parent", () => {
    const [nose, left, right] = portTree(preview.ports);

    expect(nose.children.map((child) => child.port.name)).toEqual([
      "hardpoint_class_2",
    ]);
    expect(left.children[0].port.position).toEqual([1, 0, 0]);
    expect(right.children[0].port.position).toEqual([2, 0, 0]);
  });

  it("drops a port whose parent is not listed before it", () => {
    expect(portTree([port("orphan", { parent: "missing" })])).toEqual([]);
  });
});

describe("loadoutMounts", () => {
  it("draws the stock ship's stripped parts from their default holos", () => {
    const [nose, left, right] = loadoutMounts(preview);

    expect(nose.path).toBe(holo("mount_gimbal_s3"));
    expect(nose.position).toEqual([0, -1.17, -10.59]);
    expect(nose.mounts[0].path).toBe(holo("gats_ballisticgatling_s3"));
    // The barrel is in the gatling's holo already.
    expect(nose.mounts[0].mounts).toEqual([]);
    expect(left.mounts[0].path).toBe(holo("misl_s02_ir_fski_ignite"));
    expect(right.mounts[0].position).toEqual([2, 0, 0]);
  });

  it("leaves out what stays in the hull", () => {
    expect(loadoutMounts(preview)).toHaveLength(3);
  });

  it("draws the part a loadout fits in place of the stock one", () => {
    const slots = [
      slot("hardpoint_gun_nose", {
        stock: { id: "gimbal", name: "Gimbal", holoUrl: holo("gimbal") },
        slots: [
          slot("hardpoint_class_2", {
            stock: { id: "gatling", name: "Gatling" },
            fitted: {
              id: "repeater",
              name: "Repeater",
              scKey: "klwe_laserrepeater_s3",
              holoUrl: holo("klwe_laserrepeater_s3"),
            },
          }),
        ],
      }),
    ];

    const [nose] = loadoutMounts(preview, previewSlotsFromLoadout(slots));

    expect(nose.path).toBe(holo("gimbal"));
    expect(nose.mounts[0].path).toBe(holo("klwe_laserrepeater_s3"));
  });

  it("leaves the stock part's defaults off a refitted part", () => {
    const [nose] = loadoutMounts(
      preview,
      previewSlotsFromLoadout([
        slot("hardpoint_gun_nose", {
          stock: { id: "gimbal", name: "Gimbal", holoUrl: holo("gimbal") },
          fitted: { id: "turret", name: "Turret", holoUrl: holo("turret") },
          // The turret's own port is named apart from the gimbal's.
          slots: [slot("turret_gun", {})],
        }),
      ]),
    );

    expect(nose.path).toBe(holo("turret"));
    expect(nose.mounts).toEqual([]);
  });

  it("matches slots to ports whatever their case", () => {
    const [nose] = loadoutMounts(
      preview,
      previewSlotsFromLoadout([
        slot("HARDPOINT_GUN_NOSE", {
          fitted: { id: "turret", name: "Turret", holoUrl: holo("turret") },
        }),
      ]),
    );

    expect(nose.path).toBe(holo("turret"));
  });

  it("draws nothing on an emptied slot or below it", () => {
    const mounts = loadoutMounts(
      preview,
      previewSlotsFromLoadout([slot("hardpoint_gun_nose", { emptied: true })]),
    );

    expect(mounts.map((mount) => mount.path)).toEqual([
      holo("mrck_s03_behr_dual_s02"),
      holo("mrck_s03_behr_dual_s02"),
    ]);
  });

  it("highlights the parts in the slots the editor has open", () => {
    const [nose, left] = loadoutMounts(preview, [
      {
        name: "hardpoint_gun_nose",
        part: { holoUrl: holo("gimbal") },
        active: true,
        slots: [],
      },
      {
        name: "hardpoint_missilerack_left",
        part: { holoUrl: holo("rack") },
        slots: [],
      },
    ]);

    expect(nose.highlighted).toBe(true);
    expect(left.highlighted).toBe(false);
  });

  it("colours each part by the tab that lists its slot", () => {
    const [nose, left] = loadoutMounts(preview, [
      {
        name: "hardpoint_gun_nose",
        part: { holoUrl: holo("gimbal") },
        category: HardpointCategoryEnum.WEAPONS,
        slots: [
          {
            name: "hardpoint_class_2",
            part: { holoUrl: holo("gun") },
            slots: [],
          },
        ],
      },
      {
        name: "hardpoint_missilerack_left",
        part: { holoUrl: holo("rack") },
        category: HardpointCategoryEnum.MISSILE_RACKS,
        slots: [],
      },
    ]);

    expect(nose.color).toBe(TAB_COLORS.weapons);
    expect(nose.mounts[0].color).toBe(TAB_COLORS.weapons);
    expect(left.color).toBe(TAB_COLORS.missiles);
  });

  it("files a saved slot's category for its colour", () => {
    const [mount] = previewSlotsFromLoadout([
      slot("hardpoint_shield", {
        category: HardpointCategoryEnum.SHIELDGENERATOR,
      }),
    ]);

    expect(categoryColor(mount.category)).toBe(TAB_COLORS.shields);
  });

  it("places a part the export never draws from its own holo", () => {
    const mounts = loadoutMounts({
      ports: [
        port("hardpoint_shield_generator_left", {
          defaultItem: "shld_godi_s01_securehyde_scitem",
          geometry: false,
        }),
        port("hardpoint_controller_shield", {
          defaultItem: "controller_shield",
          geometry: false,
        }),
      ],
      servicingAreas: [],
      cargoGrids: [],
      doors: [],
      items: [
        {
          scKey: "shld_godi_s01_securehyde_scitem",
          holoUrl: holo("shld_godi_s01_securehyde_scitem"),
        },
      ],
    });

    expect(mounts.map((mount) => mount.path)).toEqual([
      holo("shld_godi_s01_securehyde_scitem"),
    ]);
  });

  it("skips a port whose position is unknown", () => {
    const mounts = loadoutMounts({
      ports: [
        port("hardpoint_radar", {
          helper: false,
          defaultItem: "mount_gimbal_s3",
          stripped: true,
        }),
      ],
      items: preview.items,
      servicingAreas: [],
      cargoGrids: [],
      doors: [],
    });

    expect(mounts).toEqual([]);
  });
});

describe("loadoutCargoGrids", () => {
  const grid = (
    name: string,
    port: string | null,
    parentPort: string | null,
  ) => ({
    name,
    port,
    parentPort,
    position: [0, 1, 2],
    rotation: [0, 0, 0, 1],
    size: [5, 5, 7.5],
    scu: 96,
    stripped: false,
  });

  const withGrids = {
    ...preview,
    cargoGrids: [
      grid("hardpoint_cargogrid_main", null, null),
      grid(
        "hardpoint_cargogrid_module_04",
        "hardpoint_cargogrid_module_04",
        "hardpoint_module_04",
      ),
    ],
  };

  it("draws every grid of the stock ship", () => {
    expect(loadoutCargoGrids(withGrids).map((each) => each.id)).toEqual([
      "hardpoint_cargogrid_main",
      "hardpoint_cargogrid_module_04",
    ]);
  });

  it("drops a grid whose module was taken out or swapped", () => {
    const emptied = { name: "hardpoint_module_04", part: null, slots: [] };
    const refitted = {
      name: "Hardpoint_Module_04",
      part: { holoUrl: holo("other_module") },
      refitted: true,
      slots: [],
    };

    expect(
      loadoutCargoGrids(withGrids, [emptied]).map((each) => each.id),
    ).toEqual(["hardpoint_cargogrid_main"]);
    expect(
      loadoutCargoGrids(withGrids, [refitted]).map((each) => each.id),
    ).toEqual(["hardpoint_cargogrid_main"]);
  });
  it("goes by the hull's own slots alone, not a namesake inside a part", () => {
    const nested = {
      name: "hardpoint_turret",
      part: { holoUrl: holo("turret") },
      slots: [{ name: "hardpoint_module_04", part: null, slots: [] }],
    };

    expect(loadoutCargoGrids(withGrids, [nested])).toHaveLength(2);
  });
});

describe("builtInHighlights", () => {
  it("marks nothing merged into a larger piece, nor a seat named for a beam", () => {
    // The Caterpillar: the command module's tractor turret and guns all name
    // the module's node.
    const ports = [
      port("hardpoint_tractor_beam", {
        parent: "itemport_vehicle_attach",
        editable: false,
        hullNode: "itemport_vehicle_attach",
        itemKind: HullItemKindEnum.TURRET,
      }),
      port("turret_weapon", {
        parent: "hardpoint_tractor_beam",
        editable: false,
        hullNode: "itemport_vehicle_attach",
        itemKind: HullItemKindEnum.UTILITY,
        defaultItem: "grin_tractorbeam_s2",
        types: [{ type: "TractorBeam", subTypes: "" }],
      }),
      port("hardpoint_weapon_left", {
        parent: "itemport_vehicle_attach",
        editable: false,
        hullNode: "itemport_vehicle_attach",
        itemKind: HullItemKindEnum.WEAPON,
      }),
      port("hardpoint_seat_tractorbeam_right", {
        editable: false,
        hullNode: "hardpoint_seat_tractorbeam_right",
        itemKind: HullItemKindEnum.OTHER,
        defaultItem: "drak_caterpillar_scitem_seat_tractorbeam",
        types: [{ type: "Seat", subTypes: "" }],
      }),
    ];

    expect(builtInHighlights(ports)).toEqual([]);
  });

  it("leaves a locked mount whose part the loadout swaps unmarked", () => {
    // The Prospector: a locked arm holds a locked gimbal, whose mining head is
    // the loadout's to change.
    const ports = [
      port("hardpoint_mining_arm", {
        editable: false,
        hullNode: "hardpoint_mining_arm",
        itemKind: HullItemKindEnum.UTILITY,
      }),
      port("hardpoint_mining_laser", {
        parent: "hardpoint_mining_arm",
        editable: false,
        hullNode: "hardpoint_mining_laser",
        itemKind: HullItemKindEnum.WEAPON,
        defaultItem: "mount_gimbal_mining",
      }),
      port("hardpoint_mining_laser", {
        parent: "hardpoint_mining_laser",
        editable: true,
        stripped: true,
        defaultItem: "mining_laser_grin_arbor_s1",
      }),
    ];

    expect(builtInHighlights(ports)).toEqual([]);
  });

  it("picks out fixed weapons, tractor beams and mining bags only", () => {
    const ports = [
      port("hardpoint_mining_laser", {
        editable: false,
        hullNode: "hardpoint_mining_laser",
        itemKind: HullItemKindEnum.WEAPON,
      }),
      port("hardpoint_tractor_beam", {
        editable: false,
        hullNode: "hardpoint_tractor_beam",
        itemKind: HullItemKindEnum.UTILITY,
        types: [{ type: "TractorBeam", subTypes: "" }],
      }),
      port("hardpoint_tractor_rear", {
        editable: false,
        hullNode: "hardpoint_tractor_rear",
        itemKind: HullItemKindEnum.UTILITY,
        defaultItem: "grin_tractorbeam_s1",
      }),
      port("hardpoint_turret_manned_rear", {
        editable: false,
        hullNode: "hardpoint_turret_manned_rear",
        itemKind: HullItemKindEnum.TURRET,
      }),
      port("hardpoint_thruster_main", {
        editable: false,
        hullNode: "hardpoint_thruster_main",
        itemKind: HullItemKindEnum.THRUSTER,
      }),
      port("hardpoint_stored_pod_1", {
        editable: false,
        hullNode: "hardpoint_stored_pod_1",
        itemKind: HullItemKindEnum.OTHER,
        defaultItem: "cargo_shipmining_pod_prospector_collapsed",
      }),
      port("hardpoint_seat_pilot", {
        editable: false,
        hullNode: "hardpoint_seat_pilot",
        itemKind: HullItemKindEnum.OTHER,
        defaultItem: "misc_prospector_scitem_seat",
      }),
      port("hardpoint_gun_nose", { itemKind: HullItemKindEnum.WEAPON }),
      port("hardpoint_gun_hidden", {
        editable: false,
        itemKind: HullItemKindEnum.WEAPON,
      }),
    ];

    expect(builtInHighlights(ports)).toEqual([
      { id: "hardpoint_mining_laser", node: "hardpoint_mining_laser" },
      { id: "hardpoint_tractor_beam", node: "hardpoint_tractor_beam" },
      { id: "hardpoint_tractor_rear", node: "hardpoint_tractor_rear" },
      { id: "hardpoint_stored_pod_1", node: "hardpoint_stored_pod_1" },
    ]);
  });
});
