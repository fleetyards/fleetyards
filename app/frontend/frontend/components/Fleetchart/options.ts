import {
  metricsOf,
  modelOf,
  shipLabelOf,
  type FleetchartEntry,
  type FleetchartShip,
} from "@/frontend/components/Fleetchart/geometry";
import type { HangarGroup, HangarGroupPublic, Vehicle } from "@/services/fyApi";
import {
  FLEET_SHIP_GROUPS,
  FleetchartGroups,
  HANGAR_SHIP_GROUPS,
  FleetchartShipStates,
  FleetchartSorts,
} from "@/shared/stores/fleetchart";

// What any list of ships can be grouped by.
export const BASE_GROUPS = Object.values(FleetchartGroups).filter(
  (group) =>
    !FLEET_SHIP_GROUPS.includes(group) && !HANGAR_SHIP_GROUPS.includes(group),
);

// What the ships of a hangar or wishlist can be grouped by.
export const HANGAR_GROUPS = [...BASE_GROUPS, ...HANGAR_SHIP_GROUPS];

// A group chosen on a chart that offers it falls back to none on one that does not.
export const effectiveGroup = (
  group: FleetchartGroups,
  available: FleetchartGroups[],
) => (available.includes(group) ? group : FleetchartGroups.NONE);

const byHangarGroupOrder = (
  a: HangarGroup | HangarGroupPublic,
  b: HangarGroup | HangarGroupPublic,
) =>
  (a.sort ?? Number.MAX_SAFE_INTEGER) - (b.sort ?? Number.MAX_SAFE_INTEGER) ||
  a.name.localeCompare(b.name);

// A ship in several groups is drawn once, in the first of them.
const hangarGroupOf = (entry: FleetchartEntry) =>
  [...((entry as Vehicle).hangarGroups ?? [])].sort(byHangarGroupOrder)[0];

const groupKeyOf = (entry: FleetchartEntry, group: FleetchartGroups) => {
  const model = modelOf(entry);

  switch (group) {
    case FleetchartGroups.MANUFACTURER:
      return model.manufacturer?.name ?? "";
    case FleetchartGroups.CLASSIFICATION:
      return model.classificationLabel ?? model.classification ?? "";
    case FleetchartGroups.STATUS:
      return model.productionStatus ?? "";
    case FleetchartGroups.SQUADRON:
      return (entry as FleetchartShip).squadron?.name ?? "";
    case FleetchartGroups.CAPTAIN:
      return (
        (entry as FleetchartShip).userDisplayName ||
        (entry as FleetchartShip).username ||
        ""
      );
    case FleetchartGroups.HANGAR_GROUP:
      return hangarGroupOf(entry)?.name ?? "";
    default:
      return "";
  }
};

export const groupTitleOf = (
  entry: FleetchartEntry,
  group: FleetchartGroups,
  t: (key: string) => string,
) => {
  const key = groupKeyOf(entry, group);

  return group === FleetchartGroups.STATUS && key
    ? t(`labels.model.productionStatus.${key}`)
    : key;
};

const comparatorFor = (sort: FleetchartSorts, state: FleetchartShipStates) => {
  const lengthOf = (entry: FleetchartEntry) => metricsOf(entry, state).length;

  switch (sort) {
    case FleetchartSorts.LENGTH_ASC:
      return (a: FleetchartEntry, b: FleetchartEntry) =>
        lengthOf(a) - lengthOf(b);
    case FleetchartSorts.LENGTH_DESC:
      return (a: FleetchartEntry, b: FleetchartEntry) =>
        lengthOf(b) - lengthOf(a);
    case FleetchartSorts.NAME:
      return (a: FleetchartEntry, b: FleetchartEntry) =>
        shipLabelOf(a).title.localeCompare(shipLabelOf(b).title);
    default:
      return undefined;
  }
};

// Hangar groups keep the order their owner gave them, with ungrouped ships last.
const compareGroups = (
  a: FleetchartEntry,
  b: FleetchartEntry,
  group: FleetchartGroups,
) => {
  if (group !== FleetchartGroups.HANGAR_GROUP) {
    return groupKeyOf(a, group).localeCompare(groupKeyOf(b, group));
  }

  const groupA = hangarGroupOf(a);
  const groupB = hangarGroupOf(b);

  if (!groupA || !groupB) {
    return Number(!groupA) - Number(!groupB);
  }

  return byHangarGroupOrder(groupA, groupB);
};

// A copy in the chosen order, with each group's ships together. The list order
// has no comparator: it is the order the items arrive in.
export const sortEntries = (
  entries: FleetchartEntry[],
  sort: FleetchartSorts,
  group: FleetchartGroups = FleetchartGroups.NONE,
  state: FleetchartShipStates = FleetchartShipStates.FLIGHT,
) => {
  const comparator = comparatorFor(sort, state);

  return [...entries].sort(
    (a, b) => compareGroups(a, b, group) || (comparator ? comparator(a, b) : 0),
  );
};
