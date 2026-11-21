import { useI18n } from "@/shared/composables/useI18n";
import type { FilterOption, FleetInventoryStockHolder } from "@/services/fyApi";

// The select value standing for the unassigned share: a select cannot hold a
// null option apart from "nothing picked".
export const UNASSIGNED = "unassigned";

export const holderValue = (share: Pick<FleetInventoryStockHolder, "holder">) =>
  share.holder?.id ?? UNASSIGNED;

// What the API takes for a holder: an id, or null for the unassigned share.
export const holderIdFor = (value?: string | null) =>
  !value || value === UNASSIGNED ? null : value;

// The share one holder has of a set of rows -- the lots of a position, say.
export const shareOf = (
  rows: { holders?: FleetInventoryStockHolder[] }[],
  value: string,
) =>
  rows.reduce(
    (total, row) =>
      total +
      (row.holders ?? [])
        .filter((share) => holderValue(share) === value)
        .reduce((sum, share) => sum + Number(share.netQuantity), 0),
    0,
  );

export const useStockHolders = () => {
  const { t } = useI18n();

  const holderName = (share: Pick<FleetInventoryStockHolder, "holder">) =>
    share.holder?.username ?? t("labels.logistics.unassigned");

  // Each holder once, largest share first and the unassigned share last -- the
  // order the API sorts a single row in. With a unit, the label says what they
  // carry across the rows; rows in different units do not add up, so without
  // one it is the name alone.
  const holderOptions = (
    rows: { holders?: FleetInventoryStockHolder[] }[],
    unit?: string,
  ): FilterOption[] => {
    const seen = new Map<string, FleetInventoryStockHolder>();

    rows.forEach((row) =>
      (row.holders ?? []).forEach((share) => {
        if (!seen.has(holderValue(share))) seen.set(holderValue(share), share);
      }),
    );

    return [...seen.entries()]
      .map(([value, share]) => ({ value, share, total: shareOf(rows, value) }))
      .sort(
        (a, b) =>
          Number(a.value === UNASSIGNED) - Number(b.value === UNASSIGNED) ||
          b.total - a.total,
      )
      .map(({ value, share, total }) => ({
        value,
        label: unit
          ? `${holderName(share)} · ${total} ${t(`labels.logistics.units.${unit}`)}`
          : holderName(share),
      }));
  };

  return { holderName, holderOptions };
};
