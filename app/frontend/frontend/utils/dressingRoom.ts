import { type LocationQuery } from "vue-router";
import { type HoloMount } from "@/shared/components/HoloViewer/mounts";
import {
  type BodyRegion,
  type HoloRig,
  type RigAttachment,
} from "@/shared/components/HoloViewer/rig";
import {
  type CharacterBody,
  type CharacterBodyClip,
  type MediaFile,
  OutfitBodyEnum,
  OutfitSlotEnum,
  type OutfitWeaponSlotEnum,
} from "@/services/fyApi";

// Head to toe, the order the slots are listed in.
export const OUTFIT_SLOTS: OutfitSlotEnum[] = [
  OutfitSlotEnum.HELMET,
  OutfitSlotEnum.TORSO,
  OutfitSlotEnum.ARMS,
  OutfitSlotEnum.LEGS,
  OutfitSlotEnum.BACKPACK,
  OutfitSlotEnum.UNDERSUIT,
];

// Primaries on the back, a sidearm in the thigh holster.
export const WEAPON_SLOTS: OutfitSlotEnum[] = [
  OutfitSlotEnum.PRIMARY,
  OutfitSlotEnum.SECONDARY,
  OutfitSlotEnum.SIDEARM,
];

export const ALL_SLOTS = [...OUTFIT_SLOTS, ...WEAPON_SLOTS];

export const isWeaponSlot = (slot?: string): slot is OutfitWeaponSlotEnum =>
  WEAPON_SLOTS.includes(slot as OutfitSlotEnum);

// What each weapon slot takes, by the weapon's sub type; the same rule the API
// checks.
export const WEAPON_SUB_TYPES: Partial<Record<OutfitSlotEnum, string[]>> = {
  [OutfitSlotEnum.PRIMARY]: ["Medium", "Large"],
  [OutfitSlotEnum.SECONDARY]: ["Medium"],
  [OutfitSlotEnum.SIDEARM]: ["Small"],
};

// Where each slot's item hangs, as the game's ports say: the bone the worn
// core, legs or undersuit brings, and the helper on the item that meets it.
export type Mount = {
  bone: string;
  helper?: string;
  // A fixed offset in place of a helper on the item: a weapon in hand sits by
  // its origin, turned into the hand's axes.
  fixed?: { position: number[]; rotation: number[] };
};

export const STOWED_MOUNTS: Partial<Record<OutfitSlotEnum, Mount>> = {
  [OutfitSlotEnum.PRIMARY]: {
    bone: "wep_stocked_attach_3_override",
    helper: "attach_offset_left_01",
  },
  [OutfitSlotEnum.SECONDARY]: {
    bone: "wep_stocked_attach_2_override",
    helper: "attach_offset_right_01",
  },
  [OutfitSlotEnum.SIDEARM]: {
    bone: "wep_sidearm_attach_override",
    helper: "attach_offset_left_01",
  },
};

// In hand the weapon's origin, its grip, sits on the body's weapon bone,
// turned as the export says the holo needs there.
export const handMount = (body?: CharacterBody): Mount => ({
  bone: body?.weaponInHand?.bones.right ?? "RightWeaponBone",
  fixed: body?.weaponInHand?.helper,
});

// A rifle in hand is held in this pose unless another is picked.
export const RIFLE_HOLD_CLIP = "hold_rifle_lowered";

// Bound in this order: a backpack hangs from a bone the core brings, so the
// core goes first.
export const RIG_ORDER: OutfitSlotEnum[] = [
  OutfitSlotEnum.UNDERSUIT,
  OutfitSlotEnum.TORSO,
  OutfitSlotEnum.ARMS,
  OutfitSlotEnum.LEGS,
  OutfitSlotEnum.HELMET,
  OutfitSlotEnum.BACKPACK,
];

// Where the core carries a backpack that is not rigged to the body.
export const BACKPACK_MOUNT: Mount = {
  bone: "backpack_attach_1_override",
  helper: "backpack_attach_1_loc",
};

// Equipment slug per slot: what a share link carries.
export type OutfitSelection = Partial<Record<OutfitSlotEnum, string>>;

export const parseOutfitQuery = (query: LocationQuery): OutfitSelection =>
  Object.fromEntries(
    ALL_SLOTS.flatMap((slot) => {
      // A key repeated in the address comes back as a list; the first wins.
      const value = [query[slot]].flat()[0];

      return typeof value === "string" && value ? [[slot, value]] : [];
    }),
  );

export const outfitQuery = (selection: OutfitSelection) =>
  Object.fromEntries(ALL_SLOTS.map((slot) => [slot, selection[slot]]));

export const sameOutfit = (a: OutfitSelection, b: OutfitSelection) =>
  ALL_SLOTS.every((slot) => a[slot] === b[slot]);

type ItemHolos = {
  holo?: MediaFile | null;
  holoTextured?: MediaFile | null;
  holoRiggedMale?: MediaFile | null;
  holoRiggedFemale?: MediaFile | null;
};

export interface PieceHolo {
  path: string;
  size?: number;
  textured: boolean;
  // The plain holo, for a painted one that does not load.
  fallbackPath?: string;
}

// On a body, the piece's rig for it: only a rig follows the body's pose.
export const riggedPieceHolo = (
  media?: ItemHolos | null,
  body: OutfitBodyEnum = OutfitBodyEnum.MALE,
): PieceHolo | undefined => {
  const rigged =
    body === OutfitBodyEnum.FEMALE
      ? media?.holoRiggedFemale
      : media?.holoRiggedMale;

  return rigged?.url
    ? { path: rigged.url, size: rigged.size ?? undefined, textured: false }
    : undefined;
};

// The painted holo where there is one, the plain one otherwise.
export const pieceHolo = (
  media?: ItemHolos | null,
  failedPaths: string[] = [],
): PieceHolo | undefined => {
  const textured = media?.holoTextured?.url;
  const plain = media?.holo?.url;

  if (textured && !failedPaths.includes(textured)) {
    return {
      path: textured,
      size: media?.holoTextured?.size ?? undefined,
      textured: true,
      fallbackPath: plain ?? undefined,
    };
  }

  if (!plain) return undefined;

  return { path: plain, size: media?.holo?.size ?? undefined, textured: false };
};

// What the holo viewer draws: the root holo with every other piece mounted on
// it, or a rigged body wearing the pieces.
export interface OutfitHoloModel {
  path: string;
  size?: number;
  textured: boolean;
  frameMounts?: true;
  mounts?: HoloMount[];
  rig?: HoloRig;
}

export const DEFAULT_CLIP = "idle_stand";

// The pose a figure starts in: standing idle, else the first single-frame
// one, a shop display.
export const defaultClip = (clips: CharacterBodyClip[] = []) =>
  (
    clips.find((clip) => clip.name === DEFAULT_CLIP) ??
    clips.find((clip) => clip.static) ??
    clips[0]
  )?.name;

// A clip's name as the export writes it, made readable: "shop_pose_01" reads
// "Shop pose 01".
export const clipLabel = (name: string) => {
  const words = name.replace(/_/g, " ").trim();

  return words.charAt(0).toUpperCase() + words.slice(1);
};

type AttachPoints = Record<string, { position: number[]; rotation: number[] }>;

// The payload camelizes every key, the game's helper names among them:
// `attach_offset_left_01` arrives as `attachOffsetLeft01`.
const camelized = (name: string) =>
  name.replace(/_([a-z0-9])/g, (_match, next: string) => next.toUpperCase());

const helperFor = (mount: Mount, attachPoints?: AttachPoints | null) => {
  if (mount.fixed) return mount.fixed;

  if (!mount.helper || !attachPoints) return undefined;

  const point =
    attachPoints[camelized(mount.helper)] ?? attachPoints[mount.helper];

  return point
    ? { position: point.position, rotation: point.rotation }
    : undefined;
};

// A rigid item pinned to a bone of the figure, from its ordinary holo, by the
// item's helper for that mount where the export lists it.
export const attachment = (
  holo: PieceHolo,
  mount: Mount,
  attachPoints?: AttachPoints | null,
): RigAttachment => ({
  path: holo.path,
  bone: mount.bone,
  size: holo.size,
  textured: holo.textured,
  fallbackPath: holo.fallbackPath,
  helper: helperFor(mount, attachPoints),
});

// The body's regions each worn slot covers: the undersuit all of it but the
// head, the helmet the head.
export const COVERED_REGIONS: Partial<Record<OutfitSlotEnum, BodyRegion[]>> = {
  [OutfitSlotEnum.UNDERSUIT]: ["torso", "arms", "legs"],
  [OutfitSlotEnum.TORSO]: ["torso"],
  [OutfitSlotEnum.ARMS]: ["arms"],
  [OutfitSlotEnum.LEGS]: ["legs"],
  [OutfitSlotEnum.HELMET]: ["head"],
};

const coveredRegions = (slots: OutfitSlotEnum[]): BodyRegion[] => [
  ...new Set(slots.flatMap((slot) => COVERED_REGIONS[slot] ?? [])),
];

// Under a drawn undersuit the body is not drawn; under armour alone it is
// drawn as a dark undersuit, and under a helmet the head is not drawn.
const bodyCover = (worn: OutfitSlotEnum[]) => {
  const undersuit = worn.includes(OutfitSlotEnum.UNDERSUIT);
  const regions = coveredRegions(worn);
  const hide = regions.filter((region) => region === "head" || undersuit);
  const cover = regions.filter((region) => !hide.includes(region));

  return {
    ...(hide.length ? { hide } : {}),
    ...(cover.length ? { cover } : {}),
  };
};

export const riggedOutfitModel = (
  body: CharacterBody,
  pieces: PieceHolo[],
  clip?: string,
  attachments: RigAttachment[] = [],
  worn: OutfitSlotEnum[] = [],
): OutfitHoloModel => ({
  path: body.holo.url,
  size: body.holo.size ?? undefined,
  textured: false,
  rig: {
    pieces: pieces.map((piece) => ({ path: piece.path, size: piece.size })),
    ...(attachments.length ? { attachments } : {}),
    ...(body.lighting?.length ? { lights: body.lighting } : {}),
    ...bodyCover(worn),
    animations: body.animations?.url ?? undefined,
    clip:
      clip && body.clips.some((candidate) => candidate.name === clip)
        ? clip
        : defaultClip(body.clips),
    pedestal: true,
  },
});

const IDENTITY = {
  position: [0, 0, 0] as [number, number, number],
  rotation: [0, 0, 0, 1] as [number, number, number, number],
};

// Without a body, the static holos: every worn piece is exported in one frame,
// so the first is the root and the others are mounted on it at the origin.
export const outfitModel = (
  pieces: PieceHolo[],
): OutfitHoloModel | undefined => {
  const [root, ...mounted] = pieces;

  if (!root) return undefined;

  return {
    path: root.path,
    size: root.size,
    textured: root.textured,
    frameMounts: true,
    mounts: mounted.map((piece): HoloMount => ({
      ...IDENTITY,
      path: piece.path,
      size: piece.size,
      textured: piece.textured,
      fallbackPath: piece.fallbackPath,
      mounts: [],
    })),
  };
};
