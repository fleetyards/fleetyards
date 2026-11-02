import { type LocationQuery } from "vue-router";
import { type HoloMount } from "@/shared/components/HoloViewer/mounts";
import { type MediaFile, OutfitSlotEnum } from "@/services/fyApi";

// Head to toe, the order the slots are listed in.
export const OUTFIT_SLOTS: OutfitSlotEnum[] = [
  OutfitSlotEnum.HELMET,
  OutfitSlotEnum.TORSO,
  OutfitSlotEnum.ARMS,
  OutfitSlotEnum.LEGS,
  OutfitSlotEnum.BACKPACK,
  OutfitSlotEnum.UNDERSUIT,
];

// Equipment slug per slot: what a share link carries.
export type OutfitSelection = Partial<Record<OutfitSlotEnum, string>>;

export const parseOutfitQuery = (query: LocationQuery): OutfitSelection =>
  Object.fromEntries(
    OUTFIT_SLOTS.flatMap((slot) => {
      // A key repeated in the address comes back as a list; the first wins.
      const value = [query[slot]].flat()[0];

      return typeof value === "string" && value ? [[slot, value]] : [];
    }),
  );

export const outfitQuery = (selection: OutfitSelection) =>
  Object.fromEntries(OUTFIT_SLOTS.map((slot) => [slot, selection[slot]]));

export const sameOutfit = (a: OutfitSelection, b: OutfitSelection) =>
  OUTFIT_SLOTS.every((slot) => a[slot] === b[slot]);

type ItemHolos = {
  holo?: MediaFile | null;
  holoTextured?: MediaFile | null;
};

export interface PieceHolo {
  path: string;
  size?: number;
  textured: boolean;
  // The plain holo, for a painted one that does not load.
  fallbackPath?: string;
}

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
// it.
export interface OutfitHoloModel {
  path: string;
  size?: number;
  textured: boolean;
  frameMounts: true;
  mounts: HoloMount[];
}

const IDENTITY = {
  position: [0, 0, 0] as [number, number, number],
  rotation: [0, 0, 0, 1] as [number, number, number, number],
};

// Every worn piece is exported in the body's frame, so each is mounted at the
// origin. Without a body the first piece is the root: the others share its
// frame all the same.
export const outfitModel = (
  body: MediaFile | undefined,
  pieces: PieceHolo[],
): OutfitHoloModel | undefined => {
  const root: PieceHolo | undefined = body?.url
    ? { path: body.url, size: body.size ?? undefined, textured: false }
    : pieces[0];

  if (!root) return undefined;

  const mounted = root === pieces[0] ? pieces.slice(1) : pieces;

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
