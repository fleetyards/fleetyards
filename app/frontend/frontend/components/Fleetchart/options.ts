import {
  modelOf,
  shipLabelOf,
  type FleetchartEntry,
} from "@/frontend/components/Fleetchart/geometry";
import { FleetchartGroups, FleetchartSorts } from "@/shared/stores/fleetchart";

const lengthOf = (entry: FleetchartEntry) =>
  modelOf(entry).metrics?.length ?? 0;

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

const COMPARATORS: Partial<
  Record<FleetchartSorts, (a: FleetchartEntry, b: FleetchartEntry) => number>
> = {
  [FleetchartSorts.LENGTH_ASC]: (a, b) => lengthOf(a) - lengthOf(b),
  [FleetchartSorts.LENGTH_DESC]: (a, b) => lengthOf(b) - lengthOf(a),
  [FleetchartSorts.NAME]: (a, b) =>
    shipLabelOf(a).title.localeCompare(shipLabelOf(b).title),
};

// A copy in the chosen order, with each group's ships together. The list order
// has no comparator: it is the order the items arrive in.
export const sortEntries = (
  entries: FleetchartEntry[],
  sort: FleetchartSorts,
  group: FleetchartGroups = FleetchartGroups.NONE,
) => {
  const comparator = COMPARATORS[sort];

  return [...entries].sort(
    (a, b) =>
      groupKeyOf(a, group).localeCompare(groupKeyOf(b, group)) ||
      (comparator ? comparator(a, b) : 0),
  );
};
