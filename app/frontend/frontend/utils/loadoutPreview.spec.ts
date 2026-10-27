import { describe, expect, it } from "vitest";
import type {
  LoadoutSlot,
  ModelLoadoutPreview,
  ModelLoadoutPreviewPort,
} from "@/services/fyApi";
import {
  loadoutMounts,
  portTree,
  previewSlotsFromLoadout,
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
    });

    expect(mounts).toEqual([]);
  });
});
