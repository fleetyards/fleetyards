import { Matrix4, Quaternion, Vector3 } from "three";
import type {
  LoadoutComponentRef,
  LoadoutSlot,
  ModelLoadoutPreview,
  ModelLoadoutPreviewCargoGrid,
  ModelLoadoutPreviewDoor,
  ModelLoadoutPreviewDoorBounds,
  ModelLoadoutPreviewModuleHull,
  ModelLoadoutPreviewPort,
} from "@/services/fyApi";
import {
  componentTabOf,
  type FittedSlot,
  filedCategory,
  fittedCategory,
} from "@/frontend/composables/useComponentFitting";
import type { HoloMount } from "@/shared/components/HoloViewer/mounts";
import type { HoloBuiltIn } from "@/shared/components/HoloViewer/builtIns";
import type { HoloCargoGrid } from "@/shared/components/HoloViewer/cargo";
import { HullItemKindEnum } from "@/services/fyApi";

// A slot as the preview reads it: the part in it -- null for none -- and the
// slots that part brings.
export type PreviewSlot = {
  name: string;
  // The fitting's path to it, which a click on its part on the holo names.
  path?: string;
  part:
    | (Pick<LoadoutComponentRef, "holoUrl" | "scKey"> &
        Partial<
          Pick<
            LoadoutComponentRef,
            "name" | "slug" | "size" | "itemClassLabel" | "gradeLabel"
          >
        >)
    | null;
  // Whether a loadout can fit anything else here.
  changeable?: boolean;
  // The slot the editor has open.
  active?: boolean;
  // Holding another part than the stock one, whose ports the stock part's
  // defaults do not describe.
  refitted?: boolean;
  // What the slot is filed under, which picks the colour of its part.
  category?: string;
  // A docking port with a vehicle on it: holding no part, it is not empty.
  docked?: boolean;
  slots: PreviewSlot[];
};

// One colour per tab of the editor, so a part on the holo reads as the tab
// that lists it.
export const TAB_COLORS: Record<string, string> = {
  weapons: "#c25450",
  missiles: "#c9783f",
  shields: "#4f7fc4",
  powerPlants: "#c9a83a",
  coolers: "#46a9b8",
  quantumDrives: "#8a62c0",
  radar: "#4f9e66",
  lifeSupport: "#c06a96",
  flightBlades: "#a8b3c2",
  auxiliary: "#8fae4a",
};

export const categoryColor = (category?: string) => {
  const tab = componentTabOf(category);

  return tab ? TAB_COLORS[tab.id] : undefined;
};

// A saved loadout's tree.
export const previewSlotsFromLoadout = (slots: LoadoutSlot[]): PreviewSlot[] =>
  slots.map((slot) => ({
    name: slot.name,
    part: slot.emptied ? null : (slot.fitted ?? slot.stock ?? null),
    docked: !!slot.docked,
    refitted: !!slot.fitted && slot.fitted.id !== slot.stock?.id,
    category: filedCategory(slot),
    slots: previewSlotsFromLoadout(slot.slots),
  }));

// The editor's fitting, unsaved changes included, and the slot paths it has
// open.
export const previewSlotsFromFitting = (
  tree: FittedSlot[],
  activePaths: string[] = [],
): PreviewSlot[] =>
  tree.map((entry) => ({
    name: entry.slot.name,
    path: entry.path,
    part: entry.content ?? null,
    docked: !!entry.slot.docked,
    active: activePaths.includes(entry.path),
    refitted: !!entry.content && entry.content.id !== entry.slot.stock?.id,
    changeable: entry.slot.editable !== false && entry.slot.swappable !== false,
    category: fittedCategory(entry),
    slots: previewSlotsFromFitting(entry.children, activePaths),
  }));

type PortNode = {
  port: ModelLoadoutPreviewPort;
  children: PortNode[];
};

// The game mixes `Hardpoint_cooler_left` and `hardpoint_power_plant`.
const sameName = (a: string, b: string) => a.toLowerCase() === b.toLowerCase();

// A nested port hangs off the last port before it with its parent's name: every
// rack has its own `missile_01_attach`, and each follows its rack.
export const portTree = (ports: ModelLoadoutPreviewPort[]) => {
  const roots: PortNode[] = [];
  const seen: PortNode[] = [];

  for (const port of ports) {
    const node: PortNode = { port, children: [] };

    if (port.parent) {
      const parentName = port.parent;
      const parent = seen.findLast((candidate) =>
        sameName(candidate.port.name, parentName),
      );

      // Without its parent there is no frame to place it in.
      if (!parent) continue;

      parent.children.push(node);
    } else {
      roots.push(node);
    }

    seen.push(node);
  }

  return roots;
};

/**
 * What to draw on the hull holo for a fitting: the part each stripped port
 * holds, from the loadout's slot where it has one and the port's default
 * otherwise. Everything else is in the hull already, or drawn by the holo of
 * the part it belongs to.
 */
// Whether the preview draws the part on a port itself: a part the hull leaves
// out, one the export never draws -- a shield generator, in neither the hull
// nor any holo -- or one the ship comes without, as the Idris-P's nose.
const portDrawn = (port: ModelLoadoutPreviewPort) =>
  (port.stripped || !port.geometry || !port.defaultItem) &&
  !port.inParentHolo &&
  port.helper;

const moduleHullsByKey = (preview: ModelLoadoutPreview) =>
  new Map(
    (preview.moduleHulls ?? []).map((hull) => [hull.scKey.toLowerCase(), hull]),
  );

// The hull of the module a port holds: the one fitted in its slot, or with no
// slot to say or nothing fitted, the one the ship comes with -- the Galaxy's
// empty bay is its base module, not a hole.
const moduleHullFor = (
  hulls: Map<string, ModelLoadoutPreviewModuleHull>,
  port: ModelLoadoutPreviewPort,
  slot: PreviewSlot | undefined,
  parentRefitted: boolean,
) => {
  if (!hulls.size) return undefined;

  let key: string | null | undefined;
  if (slot?.part) {
    key = slot.part.scKey;
  } else if (!parentRefitted) {
    key = port.defaultItem;
  }

  return key ? hulls.get(key.toLowerCase()) : undefined;
};

const UNIT = new Vector3(1, 1, 1);

const poseOf = (position: readonly number[], rotation: readonly number[]) =>
  new Matrix4().compose(
    new Vector3().fromArray(position),
    new Quaternion().fromArray(rotation),
    UNIT,
  );

const decomposed = (matrix: Matrix4) => {
  const position = new Vector3();
  const rotation = new Quaternion();
  matrix.decompose(position, rotation, new Vector3());

  return { position: position.toArray(), rotation: rotation.toArray() };
};

const placeBox = (
  box: ModelLoadoutPreviewDoorBounds | null,
  pose: Matrix4,
  turn: Quaternion,
): ModelLoadoutPreviewDoorBounds | null =>
  box && {
    ...box,
    center: new Vector3().fromArray(box.center).applyMatrix4(pose).toArray(),
    axes: box.axes.map((axis) =>
      new Vector3().fromArray(axis).applyQuaternion(turn).toArray(),
    ),
  };

// A module's door in the ship's frame: its keyframes are rigid moves in the
// module's, so each is turned into the same move seen from the ship.
const placeDoor = (
  door: ModelLoadoutPreviewDoor,
  pose: Matrix4,
): ModelLoadoutPreviewDoor => {
  const turn = new Quaternion().setFromRotationMatrix(pose);
  const inverse = pose.clone().invert();

  return {
    ...door,
    position:
      door.position &&
      new Vector3().fromArray(door.position).applyMatrix4(pose).toArray(),
    bounds: placeBox(door.bounds, pose, turn),
    outline: placeBox(door.outline, pose, turn),
    parts: door.parts.map((part) => ({
      ...part,
      keyframes: part.keyframes.map((keyframe) => {
        const { position, rotation } = decomposed(
          pose
            .clone()
            .multiply(poseOf(keyframe.translation, keyframe.rotation))
            .multiply(inverse),
        );

        return { ...keyframe, translation: position, rotation };
      }),
    })),
  };
};

/**
 * What the modules fitted to the ship's slots add to its hull: their ports,
 * and their cargo grids and doors in the ship's frame, placed by the slot.
 */
export const fittedModuleHulls = (
  preview: ModelLoadoutPreview,
  slots?: PreviewSlot[],
) => {
  const hulls = moduleHullsByKey(preview);

  const fitted = preview.ports
    .filter((port) => !port.parent && portDrawn(port))
    .flatMap((port) => {
      const slot = slots?.find((candidate) =>
        sameName(candidate.name, port.name),
      );
      const hull = moduleHullFor(hulls, port, slot, false);

      return hull ? [{ port, hull }] : [];
    });

  return {
    ports: fitted.flatMap(({ hull }) => hull.ports),
    cargoGrids: fitted.flatMap(({ port, hull }) => {
      const pose = poseOf(port.position, port.rotation);

      return hull.cargoGrids.map((grid): ModelLoadoutPreviewCargoGrid => ({
        ...grid,
        ...decomposed(
          pose.clone().multiply(poseOf(grid.position, grid.rotation)),
        ),
      }));
    }),
    doors: fitted.flatMap(({ port, hull }) => {
      const pose = poseOf(port.position, port.rotation);

      return hull.doors.map((door) => placeDoor(door, pose));
    }),
  };
};

/**
 * The ship's hull as the fitting has it: its own ports, cargo grids and doors,
 * and those its fitted modules bring.
 */
export const loadoutHull = (
  preview: ModelLoadoutPreview,
  slots?: PreviewSlot[],
) => {
  const modules = fittedModuleHulls(preview, slots);

  return {
    ports: [...preview.ports, ...modules.ports],
    cargoGrids: [...preview.cargoGrids, ...modules.cargoGrids],
    doors: [...preview.doors, ...modules.doors],
  };
};

export const loadoutMounts = (
  preview: ModelLoadoutPreview,
  slots?: PreviewSlot[],
): HoloMount[] => {
  const defaultHolos = new Map(
    preview.items.map((item) => [item.scKey, item.holoUrl]),
  );
  const hulls = moduleHullsByKey(preview);

  const build = (
    nodes: PortNode[],
    levelSlots?: PreviewSlot[],
    parentRefitted = false,
    parentColor?: string,
  ) =>
    nodes.flatMap((node): HoloMount[] => {
      const { port } = node;
      const slot = levelSlots?.find((candidate) =>
        sameName(candidate.name, port.name),
      );

      // An empty slot holds nothing, and nothing sits below it; an empty
      // module slot shows the module the ship comes with.
      if (
        slot &&
        !slot.part &&
        !slot.docked &&
        !(portDrawn(port) && moduleHullFor(hulls, port, slot, parentRefitted))
      ) {
        return [];
      }

      // A part the export never draws -- a shield generator -- is in neither
      // the hull nor any holo, so it is placed like a stripped one; where it
      // has no holo of its own either, nothing comes of it.
      // A port the ship comes without a part in -- the Idris-P's nose -- has
      // nothing in the hull either, so what a loadout fits there is drawn too.
      const drawn = portDrawn(port);

      let path: string | undefined;

      // A module with a hull of its own is drawn by it, and what sits on its
      // ports by the module's own export rather than the ship's.
      const hull = drawn
        ? moduleHullFor(hulls, port, slot, parentRefitted)
        : undefined;

      if (hull) {
        path = hull.holoHullUrl;
      } else if (drawn) {
        // Under a refitted part the ship file's ports are the stock part's;
        // only the loadout's own slots say what the new one holds.
        if (slot) {
          path = slot.part?.holoUrl;
        } else if (!parentRefitted && port.defaultItem) {
          path = defaultHolos.get(port.defaultItem);
        }
      }

      // A gun in a turret is the turret's colour; a slot filed apart -- a
      // missile rack on a turret -- has its own.
      const color = categoryColor(slot?.category) ?? parentColor;

      // The export puts a docked vehicle on a port of its own below the
      // docking port, which the loadout's slots skip: its parts are the
      // docking port's slots.
      const vehicle = port.types.some(({ type }) => type === "NOITEM_Vehicle");

      let mounts: HoloMount[];
      if (hull) {
        mounts = build(portTree(hull.ports), slot?.slots, false);
      } else if (vehicle) {
        mounts = build(node.children, levelSlots, parentRefitted, color);
      } else {
        mounts = build(node.children, slot?.slots, !!slot?.refitted, color);
      }

      if (!path && !mounts.length) return [];

      return [
        {
          position: port.position as HoloMount["position"],
          rotation: port.rotation as HoloMount["rotation"],
          path,
          id: slot?.path,
          highlighted: !!slot?.active,
          color: hull ? undefined : color,
          hull: !!hull,
          mounts,
        },
      ];
    });

  return build(portTree(preview.ports), slots);
};

/**
 * The cargo grids to draw for a fitting. A grid on a module or container
 * belongs to its stock part: emptied or swapped for another, the grid goes
 * with it. The export names a grid's ports by name alone, which is unique only
 * among the hull's own slots.
 */
export const loadoutCargoGrids = (
  preview: ModelLoadoutPreview,
  slots?: PreviewSlot[],
): HoloCargoGrid[] => {
  const changed = new Set(
    (slots ?? [])
      .filter((slot) => !slot.part || slot.refitted)
      .map((slot) => slot.name.toLowerCase()),
  );

  // A grid whose port is a root port at the hull origin lost its interior's
  // placement in the export: drawn, every such grid lands in one pile.
  const unplaced = new Set(
    preview.ports
      .filter((port) => !port.parent && port.position.every((v) => v === 0))
      .map((port) => port.name.toLowerCase()),
  );

  return preview.cargoGrids
    .filter(
      (grid) =>
        !(grid.port && unplaced.has(grid.port.toLowerCase())) &&
        ![grid.port, grid.parentPort].some(
          (name) => name && changed.has(name.toLowerCase()),
        ),
    )
    .concat(fittedModuleHulls(preview, slots).cargoGrids)
    .map((grid) => ({
      id: grid.name,
      position: grid.position,
      rotation: grid.rotation,
      size: grid.size,
    }));
};

// A tractor beam item, `grin_tractorbeam_s2`: not the seat or the turret
// named after the beam it works.
const TRACTOR_BEAM = /(^|_)tractor[-_]?beam_s\d/i;
const MINING_POD = /mining[-_ ]?pod|ore[-_ ]?pod/i;

export type BuiltInKind = "weapon" | "tractorBeam" | "miningPod";

// What a built-in item is worth pointing out as on a ship's page, if anything:
// its fixed weapons, tractor beams and the bags its mining heads fill.
// Turrets, thrusters and the rest of the structure are never editable either,
// and marking them would only bury those few.
const tractorBeam = (port: ModelLoadoutPreviewPort) =>
  port.types.some((type) => type.type === "TractorBeam") ||
  TRACTOR_BEAM.test(port.defaultItem ?? "");

export const builtInKind = (
  port: ModelLoadoutPreviewPort,
  ports: ModelLoadoutPreviewPort[] = [],
): BuiltInKind | undefined => {
  // An item merged into a larger piece names that piece's node, as everything
  // on the Caterpillar's command module names the module: tinting it would mark
  // the whole module.
  if (
    port.editable ||
    !port.hullNode ||
    port.hullNode.toLowerCase() !== port.name.toLowerCase()
  ) {
    return undefined;
  }

  const item = port.defaultItem ?? "";

  if (port.itemKind === HullItemKindEnum.WEAPON) return "weapon";
  if (tractorBeam(port)) return "tractorBeam";

  // A tractor turret: the beam in it is merged into the turret's node, as the
  // Galaxy cargo module's, so the turret is what is picked out.
  const name = port.name.toLowerCase();
  if (
    ports.some(
      (child) =>
        child.parent?.toLowerCase() === name &&
        child.hullNode?.toLowerCase() === name &&
        tractorBeam(child),
    )
  ) {
    return "tractorBeam";
  }
  if (MINING_POD.test(item)) return "miningPod";

  return undefined;
};

// A locked mount whose part a loadout swaps, a mining head in its gimbal, is
// no built-in weapon: the part in it is the loadout's.
export const builtInHighlights = (
  ports: ModelLoadoutPreviewPort[],
): HoloBuiltIn[] => {
  const carriers = new Set(
    ports
      .filter((port) => port.editable && port.parent)
      .map((port) => port.parent?.toLowerCase()),
  );

  return ports
    .filter(
      (port) =>
        builtInKind(port, ports) && !carriers.has(port.name.toLowerCase()),
    )
    .map((port) => ({ id: port.name, node: port.hullNode }));
};
