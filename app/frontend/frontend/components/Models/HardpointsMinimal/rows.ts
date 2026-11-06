import { partContents } from "@/frontend/components/Models/Hardpoints/contents";
import {
  HardpointCategoryEnum,
  type ComponentThruster,
  type Hardpoint,
} from "@/services/fyApi";

export type MinimalRow = {
  key: string;
  hardpoints: Hardpoint[];
  // One row for every thruster of a type, which differ too little to list and
  // whose figure is therefore what they push together.
  total: boolean;
};

export type MinimalCategory = {
  category: HardpointCategoryEnum;
  rows: MinimalRow[];
};

// Fitted by the shipwright or too small a part of the picture for a summary.
const LEFT_OUT: HardpointCategoryEnum[] = [
  HardpointCategoryEnum.CONTROLLER,
  HardpointCategoryEnum.UNKNOWN,
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

type Placed = { hardpoint: Hardpoint; category: HardpointCategoryEnum };

const place = (
  hardpoint: Hardpoint,
  heading?: HardpointCategoryEnum,
): Placed[] => {
  const contents = partContents(hardpoint);

  if (contents.length && CARRIERS.includes(categoryOf(hardpoint))) {
    // A turret says who aims the guns, which a bare mount or rack does not.
    const carried =
      heading ??
      (hardpoint.category === HardpointCategoryEnum.TURRET
        ? HardpointCategoryEnum.TURRET
        : undefined);

    return contents.flatMap((part) => place(part, carried));
  }

  const category = heading ?? categoryOf(hardpoint);

  return [
    { hardpoint, category },
    ...contents.flatMap((part) => place(part, category)),
  ];
};

// By name, not by the server's group key: that key reads a slot by what sits
// inside it, and the same gun on two different mounts is still one row here.
const stackKey = ({ component, groupKey, id, maxSize }: Hardpoint) =>
  component?.name
    ? `${maxSize}|${component.name}`
    : `${groupKey ?? id}|${JSON.stringify([component?.size, component?.typeData ?? null])}`;

const thrustOf = (hardpoint: Hardpoint) =>
  (hardpoint.component?.typeData as ComponentThruster | undefined)
    ?.thrustCapacity;

const rowsFor = (
  category: HardpointCategoryEnum,
  hardpoints: Hardpoint[],
): MinimalRow[] => {
  if (THRUSTERS.includes(category) && hardpoints.every(thrustOf)) {
    return [{ key: category, hardpoints, total: true }];
  }

  const stacks = new Map<string, Hardpoint[]>();

  hardpoints.forEach((hardpoint) => {
    const key = stackKey(hardpoint);
    stacks.set(key, [...(stacks.get(key) ?? []), hardpoint]);
  });

  return [...stacks].map(([key, stack]) => ({
    key,
    hardpoints: stack,
    total: false,
  }));
};

const rank = (category: HardpointCategoryEnum) => {
  const index = LEADING.indexOf(category);

  return index === -1 ? LEADING.length : index;
};

export const minimalCategories = (
  hardpoints: Hardpoint[],
): MinimalCategory[] => {
  const categories = new Map<HardpointCategoryEnum, Hardpoint[]>();

  hardpoints
    .flatMap((hardpoint) => place(hardpoint))
    .filter(
      ({ hardpoint, category }) =>
        !LEFT_OUT.includes(category) &&
        !LEFT_OUT.includes(categoryOf(hardpoint)),
    )
    .forEach(({ hardpoint, category }) => {
      categories.set(category, [
        ...(categories.get(category) ?? []),
        hardpoint,
      ]);
    });

  return [...categories]
    .sort(([a], [b]) => rank(a) - rank(b) || String(a).localeCompare(String(b)))
    .map(([category, list]) => ({ category, rows: rowsFor(category, list) }));
};
