import { useI18n } from "@/shared/composables/useI18n";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import { type Commodity } from "@/services/fyApi";

/**
 * The sorts the catalogue offers above its rows.
 *
 * A row list has no column headings, so the sort line is the whole control
 * rather than a second way to reach one — which is why it lives beside the list
 * rather than inside it: `FilteredList` renders its results slot only once the
 * first page has arrived, and a control that disappears while the thing it
 * controls is loading is the wrong way round.
 */
export const useCommoditySortFields = () => {
  const { t } = useI18n();

  return computed<BaseTableCol<Commodity>[]>(() => [
    { name: "name", label: t("labels.commodity.name"), sortable: true },
    {
      name: "commodityType",
      label: t("labels.commodity.commodityType"),
      sortable: true,
    },
    // Offered whether or not the rows on screen carry a price. Half the
    // catalogue has none, and ordering by price is how a reader finds the half
    // that does — a control that appeared only once something priced was
    // already in view would be missing exactly when it is wanted.
    {
      name: "buyPrice",
      label: t("labels.commodity.buyPrice"),
      sortable: true,
    },
    {
      name: "sellPrice",
      label: t("labels.commodity.sellPrice"),
      sortable: true,
    },
  ]);
};
