import type {
  LoadoutComponentRef,
  LoadoutSlot,
  ModelLoadoutPreview,
  ModelLoadoutPreviewPort,
} from "@/services/fyApi";
import {
  componentTabOf,
  type FittedSlot,
  filedCategory,
  fittedCategory,
} from "@/frontend/composables/useComponentFitting";
import type { HoloMount } from "@/shared/components/HoloViewer/mounts";

// A slot as the preview reads it: the part in it -- null for none -- and the
// slots that part brings.
export type PreviewSlot = {
  name: string;
  // The fitting's path to it, which a click on its part on the holo names.
  path?: string;
  part: Pick<LoadoutComponentRef, "holoUrl"> | null;
  // The slot the editor has open.
  active?: boolean;
  // Holding another part than the stock one, whose ports the stock part's
  // defaults do not describe.
  refitted?: boolean;
  // What the slot is filed under, which picks the colour of its part.
  category?: string;
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
    active: activePaths.includes(entry.path),
    refitted: !!entry.content && entry.content.id !== entry.slot.stock?.id,
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
export const loadoutMounts = (
  preview: ModelLoadoutPreview,
  slots?: PreviewSlot[],
): HoloMount[] => {
  const defaultHolos = new Map(
    preview.items.map((item) => [item.scKey, item.holoUrl]),
  );

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

      // An empty slot holds nothing, and nothing sits below it.
      if (slot && !slot.part) return [];

      // A part the export never draws -- a shield generator -- is in neither
      // the hull nor any holo, so it is placed like a stripped one; where it
      // has no holo of its own either, nothing comes of it.
      const drawn =
        (port.stripped || !port.geometry) && !port.inParentHolo && port.helper;

      let path: string | undefined;

      if (drawn) {
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

      const mounts = build(node.children, slot?.slots, !!slot?.refitted, color);

      if (!path && !mounts.length) return [];

      return [
        {
          position: port.position as HoloMount["position"],
          rotation: port.rotation as HoloMount["rotation"],
          path,
          id: slot?.path,
          highlighted: !!slot?.active,
          color,
          mounts,
        },
      ];
    });

  return build(portTree(preview.ports), slots);
};
