import {
  metricsOf,
  modelOf,
  shipLabelOf,
  type FleetchartEntry,
} from "@/frontend/components/Fleetchart/geometry";
import {
  FleetchartGroups,
  FleetchartShipStates,
  FleetchartSorts,
} from "@/shared/stores/fleetchart";

const groupKeyOf = (entry: FleetchartEntry, group: FleetchartGroups) => {
  const model = modelOf(entry);

  switch (group) {
    case FleetchartGroups.MANUFACTURER:
      return model.manufacturer?.name ?? "";
    case FleetchartGroups.CLASSIFICATION:
      return model.classificationLabel ?? model.classification ?? "";
    case FleetchartGroups.STATUS:
      return model.productionStatus ?? "";
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
