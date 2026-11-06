import { partContents } from "@/frontend/components/Models/Hardpoints/contents";
import {
  HardpointCategoryEnum,
  type ComponentThruster,
  type Hardpoint,
} from "@/services/fyApi";

export interface MinimalRow {
  key: string;
  hardpoints: Hardpoint[];
  // One row for every thruster of a type, which differ too little to list and
  // whose figure is therefore what they push together.
  total: boolean;
  // The hardpoints this row stands for, with any mount or rack it leaves out, so
  // a change to one of those still shows on the row.
  relatedIds: string[];
}

export interface MinimalCategory {
  category: HardpointCategoryEnum;
  rows: MinimalRow[];
}

// Fitted by the shipwright, so no list shows them.
const NEVER_LISTED: HardpointCategoryEnum[] = [
  HardpointCategoryEnum.CONTROLLER,
  HardpointCategoryEnum.UNKNOWN,
];

// Too small a part of the picture for a summary with full rows behind it.
const LEFT_OUT: HardpointCategoryEnum[] = [
  ...NEVER_LISTED,
  HardpointCategoryEnum.FUEL_INTAKES,
  HardpointCategoryEnum.LIFESUPPORT,
];

// Parts that only hold what the ship fights with, so the summary lists what
// they hold.
const CARRIERS: HardpointCategoryEnum[] = [
  HardpointCategoryEnum.TURRET,
  HardpointCategoryEnum.WEAPON_MOUNTS,
  HardpointCategoryEnum.MISSILE_RACKS,
];

const THRUSTERS: HardpointCategoryEnum[] = [
  HardpointCategoryEnum.MAIN_THRUSTERS,
  HardpointCategoryEnum.MANEUVERING_THRUSTERS,
  HardpointCategoryEnum.RETRO_THRUSTERS,
  HardpointCategoryEnum.VTOL_THRUSTERS,
];

// Weapons read from the guns out; everything else keeps the alphabetical order
// the full list has.
const LEADING: HardpointCategoryEnum[] = [
  HardpointCategoryEnum.TURRET,
  HardpointCategoryEnum.WEAPONS,
  HardpointCategoryEnum.MISSILES,
];

const categoryOf = ({ category }: Hardpoint) =>
  category ?? HardpointCategoryEnum.UNKNOWN;

interface Placed {
  hardpoint: Hardpoint;
  category: HardpointCategoryEnum;
  carriers: string[];
}

const place = (
  hardpoint: Hardpoint,
  heading?: HardpointCategoryEnum,
  carriers: string[] = [],
): Placed[] => {
  const contents = partContents(hardpoint);

  if (contents.length && CARRIERS.includes(categoryOf(hardpoint))) {
    // A turret says who aims the guns, which a bare mount or rack does not.
    const carried =
      heading ??
      (hardpoint.category === HardpointCategoryEnum.TURRET
        ? HardpointCategoryEnum.TURRET
        : undefined);

    return contents.flatMap((part) =>
      place(part, carried, [...carriers, hardpoint.id]),
    );
  }

  const category = heading ?? categoryOf(hardpoint);

  return [
    { hardpoint, category, carriers },
    ...contents.flatMap((part) => place(part, category)),
  ];
};

// By name, not by the server's group key: that key reads a slot by what sits
// inside it, and the same gun on two different mounts is still one row here. The
// sub-type as well, because hydrogen and quantum tanks are both "Internal Tank".
// A module slot never stacks: its name comes from the reader's pick for that slot.
const stackKey = ({
  category,
  component,
  groupKey,
  id,
  maxSize,
}: Hardpoint) => {
  if (category === HardpointCategoryEnum.MODULE) return id;

  return component?.name
    ? `${maxSize}|${component.name}|${component.subType ?? ""}`
    : `${groupKey ?? id}|${JSON.stringify([component?.size, component?.typeData ?? null])}`;
};

const thrustOf = (hardpoint: Hardpoint) =>
  (hardpoint.component?.typeData as ComponentThruster | undefined)
    ?.thrustCapacity;

const rowOf = (key: string, placed: Placed[], total: boolean): MinimalRow => ({
  key,
  total,
  hardpoints: placed.map(({ hardpoint }) => hardpoint),
  relatedIds: placed.flatMap(({ hardpoint, carriers }) => [
    hardpoint.id,
    ...carriers,
  ]),
});

const stacksOf = (placed: Placed[]): MinimalRow[] => {
  const stacks = new Map<string, Placed[]>();

  placed.forEach((entry) => {
    const key = stackKey(entry.hardpoint);
    stacks.set(key, [...(stacks.get(key) ?? []), entry]);
  });

  return [...stacks].map(([key, stack]) => rowOf(key, stack, false));
};

const rowsFor = (
  category: HardpointCategoryEnum,
  placed: Placed[],
): MinimalRow[] => {
  const pushing = placed.filter(({ hardpoint }) => thrustOf(hardpoint));

  if (!THRUSTERS.includes(category) || !pushing.length) {
    return stacksOf(placed);
  }

  return [
    rowOf(category, pushing, true),
    ...stacksOf(placed.filter(({ hardpoint }) => !thrustOf(hardpoint))),
  ];
};

const rank = (category: HardpointCategoryEnum) => {
  const index = LEADING.indexOf(category);

  return index === -1 ? LEADING.length : index;
};

export const minimalCategories = (
  hardpoints: Hardpoint[],
  // Where these rows are all there is, nothing can be left for the full ones.
  { complete = false }: { complete?: boolean } = {},
): MinimalCategory[] => {
  const leftOut = complete ? NEVER_LISTED : LEFT_OUT;

  const categories = new Map<HardpointCategoryEnum, Placed[]>();

  hardpoints
    .flatMap((hardpoint) => place(hardpoint))
    .filter(
      ({ hardpoint, category }) =>
        !leftOut.includes(category) && !leftOut.includes(categoryOf(hardpoint)),
    )
    .forEach((entry) => {
      categories.set(entry.category, [
        ...(categories.get(entry.category) ?? []),
        entry,
      ]);
    });

  return [...categories]
    .sort(([a], [b]) => rank(a) - rank(b) || String(a).localeCompare(String(b)))
    .map(([category, list]) => ({ category, rows: rowsFor(category, list) }));
};

// Whether any of these hardpoints, or what sits inside them, is one of the ids.
export const holdsAny = (hardpoints: Hardpoint[], ids: Set<string>): boolean =>
  hardpoints.some(
    (hardpoint) =>
      ids.has(hardpoint.id) || holdsAny(partContents(hardpoint), ids),
  );
