import { type LocationQuery } from "vue-router";
import { OutfitHolderEnum } from "@/services/fyApi";

export const HOLDERS: OutfitHolderEnum[] = [
  OutfitHolderEnum.BACKPACK,
  OutfitHolderEnum.TORSO,
  OutfitHolderEnum.LEGS,
  OutfitHolderEnum.UNDERSUIT,
];

// The same limit the API checks.
export const MAX_STORED_QUANTITY = 999;

export interface StoredEntry {
  slug: string;
  quantity: number;
}

// What each worn piece holds, by equipment slug: what a share link carries.
export type StoredSelection = Partial<Record<OutfitHolderEnum, StoredEntry[]>>;

export interface StorageInventory {
  capacity: number;
  dimensions: { x: number; y: number; z: number };
}

export interface StorableItem {
  volume?: number | null;
  volumeDimensions?: { x?: number; y?: number; z?: number } | null;
}

export type StoreProblem = "unmeasured" | "tooLarge" | "noRoom";

const queryKey = (holder: OutfitHolderEnum) => `stored_${holder}`;

const parseEntry = (text: string): StoredEntry | undefined => {
  const [slug, count] = text.split("*");
  if (!slug) return undefined;

  const quantity = Number(count ?? 1);

  return {
    slug,
    quantity:
      Number.isInteger(quantity) && quantity > 0
        ? Math.min(quantity, MAX_STORED_QUANTITY)
        : 1,
  };
};

export const parseStoredQuery = (query: LocationQuery): StoredSelection =>
  Object.fromEntries(
    HOLDERS.flatMap((holder) => {
      const value = [query[queryKey(holder)]].flat()[0];
      if (typeof value !== "string" || !value) return [];

      const entries = value
        .split(",")
        .flatMap((text) => parseEntry(text) ?? []);

      return entries.length ? [[holder, entries]] : [];
    }),
  );

export const storedQuery = (stored: StoredSelection) =>
  Object.fromEntries(
    HOLDERS.map((holder) => [
      queryKey(holder),
      stored[holder]?.length
        ? stored[holder]
            ?.map(({ slug, quantity }) =>
              quantity > 1 ? `${slug}*${quantity}` : slug,
            )
            .join(",")
        : undefined,
    ]),
  );

export const storedSlugs = (stored: StoredSelection) => [
  ...new Set(
    HOLDERS.flatMap((holder) =>
      (stored[holder] ?? []).map((entry) => entry.slug),
    ),
  ),
];

export const setStoredQuantity = (
  stored: StoredSelection,
  holder: OutfitHolderEnum,
  slug: string,
  quantity: number,
): StoredSelection => {
  const entries = stored[holder] ?? [];
  const known = entries.some((entry) => entry.slug === slug);
  const next = known
    ? entries.map((entry) => (entry.slug === slug ? { slug, quantity } : entry))
    : [...entries, { slug, quantity }];

  return {
    ...stored,
    [holder]: next.filter((entry) => entry.quantity > 0),
  };
};

export const addStored = (
  stored: StoredSelection,
  holder: OutfitHolderEnum,
  slug: string,
) => {
  const held =
    stored[holder]?.find((entry) => entry.slug === slug)?.quantity ?? 0;

  return setStoredQuantity(
    stored,
    holder,
    slug,
    Math.min(held + 1, MAX_STORED_QUANTITY),
  );
};

export const microScu = (item?: StorableItem) =>
  Math.round((item?.volume ?? 0) * 1_000_000);

export const usedSpace = (
  entries: StoredEntry[] = [],
  items: Record<string, StorableItem | undefined>,
) =>
  entries.reduce(
    (used, entry) => used + microScu(items[entry.slug]) * entry.quantity,
    0,
  );

// An item may be turned to fit, so sides are compared longest to longest.
export const fitsInside = (inventory: StorageInventory, item: StorableItem) => {
  const sides = Object.values(item.volumeDimensions ?? {}).sort(
    (a, b) => a - b,
  );
  if (!sides.length) return true;

  const interior = Object.values(inventory.dimensions).sort((a, b) => a - b);

  return sides.every((side, index) => side <= (interior[index] ?? 0));
};

// Why one more of the item would not go in a piece holding `used` already.
export const storeProblem = (
  inventory: StorageInventory,
  item: StorableItem,
  used: number,
): StoreProblem | undefined => {
  if (!item.volume) return "unmeasured";
  if (!fitsInside(inventory, item)) return "tooLarge";
  if (used + microScu(item) > inventory.capacity) return "noRoom";

  return undefined;
};

// Whether a piece's contents still hold up against what it is, once a worn
// piece has changed underneath them.
export const holderProblem = (
  inventory: StorageInventory | null | undefined,
  entries: StoredEntry[] = [],
  items: Record<string, StorableItem | undefined>,
) => {
  if (!entries.length) return undefined;
  if (!inventory) return "noStorage";
  if (usedSpace(entries, items) > inventory.capacity) return "overCapacity";

  const tooLarge = entries.some((entry) => {
    const item = items[entry.slug];

    return !!item && !fitsInside(inventory, item);
  });

  return tooLarge ? "tooLarge" : undefined;
};
