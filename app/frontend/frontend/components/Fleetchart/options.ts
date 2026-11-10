import {
  metricsOf,
  modelOf,
  shipLabelOf,
  type FleetchartEntry,
  type FleetchartShip,
} from "@/frontend/components/Fleetchart/geometry";
import {
  FLEET_SHIP_GROUPS,
  FleetchartGroups,
  FleetchartShipStates,
  FleetchartSorts,
} from "@/shared/stores/fleetchart";

// What any list of ships can be grouped by.
export const BASE_GROUPS = Object.values(FleetchartGroups).filter(
  (group) => !FLEET_SHIP_GROUPS.includes(group),
);

// A group chosen on a chart that offers it falls back to none on one that does not.
export const effectiveGroup = (
  group: FleetchartGroups,
  available: FleetchartGroups[],
) => (available.includes(group) ? group : FleetchartGroups.NONE);

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
    (a, b) =>
      groupKeyOf(a, group).localeCompare(groupKeyOf(b, group)) ||
      (comparator ? comparator(a, b) : 0),
  );
};
