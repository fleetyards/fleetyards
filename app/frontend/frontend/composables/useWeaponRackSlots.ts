import type {
  WeaponRack,
  WeaponRackSlot,
  WeaponRackSlotType,
} from "@/services/fyApi";

export enum RackSlotCategory {
  WEAPON = "weapon",
  GADGET = "gadget",
  CARGO = "cargo",
  CARRIABLE = "carriable",
  ARMOR = "armor",
  OTHER = "other",
}

const CATEGORY_ORDER = Object.values(RackSlotCategory);

// Tags that keep a slot for one kind of item. A port tag the game uses only to
// pair a slot with its prop (`weapon_port_01`) says nothing to a reader.
export const RESTRICTING_TAGS = [
  "multitool",
  "medical_injection",
  "grenade",
] as const;

export type RestrictingTag = (typeof RESTRICTING_TAGS)[number];

export type RackSlotGroup = {
  key: string;
  categories: RackSlotCategory[];
  minSize: number;
  maxSize: number;
  restriction?: RestrictingTag;
  count: number;
  share: number;
};

const categoryOf = (type: WeaponRackSlotType): RackSlotCategory => {
  if (type.type === "WeaponPersonal") {
    return type.subTypes.length &&
      type.subTypes.every((subType) => subType === "Gadget")
      ? RackSlotCategory.GADGET
      : RackSlotCategory.WEAPON;
  }

  if (type.type === "Cargo" || type.type === "Container") {
    return RackSlotCategory.CARGO;
  }

  if (type.type === "Misc") {
    return RackSlotCategory.CARRIABLE;
  }

  if (
    type.type.startsWith("Char_Armor") ||
    type.type.startsWith("Char_Clothing")
  ) {
    return RackSlotCategory.ARMOR;
  }

  return RackSlotCategory.OTHER;
};

const categoriesOf = (slot: WeaponRackSlot): RackSlotCategory[] => {
  const found = new Set(slot.types.map(categoryOf));

  return found.size
    ? CATEGORY_ORDER.filter((category) => found.has(category))
    : [RackSlotCategory.OTHER];
};

const restrictionOf = (slot: WeaponRackSlot): RestrictingTag | undefined =>
  RESTRICTING_TAGS.find((tag) => slot.requiredTags?.includes(tag));

/**
 * Every slot across a ship's racks, grouped by what it takes and how large:
 * a 19-slot armoury and a single gadget hook read alike as a rack count, but
 * not as slots. A rack placed twice brings its slots twice.
 */
export const groupRackSlots = (racks: WeaponRack[]): RackSlotGroup[] => {
  const groups = new Map<string, RackSlotGroup>();
  let total = 0;

  racks.forEach((rack) => {
    rack.slots.forEach((slot) => {
      const categories = categoriesOf(slot);
      const restriction = restrictionOf(slot);
      const key = [
        categories.join("+"),
        slot.minSize,
        slot.maxSize,
        restriction,
      ].join("|");
      const group = groups.get(key);

      total += rack.count;

      if (group) {
        group.count += rack.count;
      } else {
        groups.set(key, {
          key,
          categories,
          minSize: slot.minSize,
          maxSize: slot.maxSize,
          restriction,
          count: rack.count,
          share: 0,
        });
      }
    });
  });

  return [...groups.values()]
    .map((group) => ({
      ...group,
      share: total ? Math.round((group.count / total) * 100) : 0,
    }))
    .sort(
      (a, b) =>
        CATEGORY_ORDER.indexOf(a.categories[0]) -
          CATEGORY_ORDER.indexOf(b.categories[0]) ||
        b.maxSize - a.maxSize ||
        b.count - a.count,
    );
};
