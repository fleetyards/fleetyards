import { OutfitSlotEnum } from "@/services/fyApi";

// What the game decides fit by, as the equipment payload carries it.
export interface FitPort {
  name: string;
  types: { type: string; subTypes?: string[] }[];
  minSize: number;
  maxSize: number;
  portTags?: string[];
  requiredTags?: string[];
}

export interface Fit {
  type: string;
  tags?: string[];
  requiredTags?: string[];
  ports?: FitPort[];
}

export interface FitItem {
  name: string;
  subType?: string | null;
  size?: string | number | null;
  fit?: Fit | null;
}

// The port each slot's item goes in, as the game names it.
const SLOT_PORTS: Partial<Record<OutfitSlotEnum, string>> = {
  [OutfitSlotEnum.TORSO]: "Armor_Torso",
  [OutfitSlotEnum.ARMS]: "Armor_Arms",
  [OutfitSlotEnum.LEGS]: "Armor_Legs",
  [OutfitSlotEnum.HELMET]: "Armor_Helmet",
  [OutfitSlotEnum.BACKPACK]: "backpack",
  [OutfitSlotEnum.PRIMARY]: "wep_stocked_3",
  [OutfitSlotEnum.SECONDARY]: "wep_stocked_2",
  [OutfitSlotEnum.SIDEARM]: "wep_sidearm",
};

// Which worn slots can offer a slot's port: the undersuit holds the armour,
// the core the backpack, and a weapon mount may be on any of them.
const PROVIDERS: Partial<Record<OutfitSlotEnum, OutfitSlotEnum[]>> = {
  [OutfitSlotEnum.TORSO]: [OutfitSlotEnum.UNDERSUIT],
  [OutfitSlotEnum.ARMS]: [OutfitSlotEnum.UNDERSUIT],
  [OutfitSlotEnum.LEGS]: [OutfitSlotEnum.UNDERSUIT],
  [OutfitSlotEnum.HELMET]: [OutfitSlotEnum.UNDERSUIT],
  [OutfitSlotEnum.BACKPACK]: [OutfitSlotEnum.TORSO],
  [OutfitSlotEnum.PRIMARY]: [
    OutfitSlotEnum.UNDERSUIT,
    OutfitSlotEnum.TORSO,
    OutfitSlotEnum.BACKPACK,
  ],
  [OutfitSlotEnum.SECONDARY]: [
    OutfitSlotEnum.UNDERSUIT,
    OutfitSlotEnum.TORSO,
    OutfitSlotEnum.BACKPACK,
  ],
  [OutfitSlotEnum.SIDEARM]: [OutfitSlotEnum.UNDERSUIT, OutfitSlotEnum.LEGS],
};

// A port's required tags carry a leading $ the item's own tags do not.
const bare = (tag: string) => tag.replace(/^\$/, "");

export const portTakes = (port: FitPort, item: FitItem) => {
  const { fit } = item;
  if (!fit) return false;

  const typed = port.types.some(
    (type) =>
      type.type === fit.type &&
      (!type.subTypes?.length ||
        (!!item.subType && type.subTypes.includes(item.subType))),
  );
  if (!typed) return false;

  const size = Number(item.size);
  if (Number.isFinite(size) && (size < port.minSize || size > port.maxSize)) {
    return false;
  }

  const tags = fit.tags ?? [];
  if (!(port.requiredTags ?? []).every((tag) => tags.includes(bare(tag)))) {
    return false;
  }

  const offered = port.portTags ?? [];

  return (fit.requiredTags ?? []).every((tag) => offered.includes(tag));
};

export type SlotFit =
  // Nothing worn that would offer this slot's port: anything goes.
  | { kind: "open" }
  // Worn, and offering the port.
  | { kind: "ports"; ports: FitPort[]; providers: FitItem[] }
  // Worn, and none of it offers the port: the slot cannot be filled.
  | { kind: "none"; providers: FitItem[] };

export const slotFit = (
  slot: OutfitSlotEnum,
  worn: Partial<Record<OutfitSlotEnum, FitItem | undefined>>,
): SlotFit => {
  const portName = SLOT_PORTS[slot];
  const providers = (PROVIDERS[slot] ?? [])
    .map((provider) => worn[provider])
    .filter((item): item is FitItem => !!item?.fit);

  if (!portName || !providers.length) return { kind: "open" };

  const ports = providers.flatMap((provider) =>
    (provider.fit?.ports ?? []).filter((port) => port.name === portName),
  );

  return ports.length
    ? { kind: "ports", ports, providers }
    : { kind: "none", providers };
};

// Whether an item may go in a slot, given what is worn.
export const fitsSlot = (fit: SlotFit, item: FitItem) => {
  if (fit.kind === "open") return true;
  if (fit.kind === "none") return false;

  return fit.ports.some((port) => portTakes(port, item));
};
