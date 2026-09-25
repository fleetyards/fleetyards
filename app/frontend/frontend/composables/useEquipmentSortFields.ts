import { useI18n } from "@/shared/composables/useI18n";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import { type Equipment } from "@/services/fyApi";

// The figures the server sorts on, by the name it whitelists, and the payload
// field that says whether a row carries one. `storage` sorts as one column
// but reads as a magazine size on a gun and a carrying capacity on a suit, so
// its sort label is the column's own.
const METRIC_SORTS = [
  { sort: "damageReduction", field: "damageReduction" },
  { sort: "radiationProtection", field: "radiationProtection" },
  { sort: "gForceTolerance", field: "gForceTolerance" },
  { sort: "rateOfFire", field: "rateOfFire" },
  { sort: "range", field: "range" },
  { sort: "storage", field: "storage" },
  { sort: "volume", field: "volume" },
] as const;

/**
 * The sorts the catalogue offers above its rows. The metric sorts appear once
 * a row on screen carries the figure, or while the list is ordered by it -- a
 * rate of fire over a page of jackets is a control that does nothing visible.
 */
export const useEquipmentSortFields = (
  equipment: MaybeRefOrGetter<Equipment[]>,
) => {
  const { t } = useI18n();

  const route = useRoute();

  const activeSort = computed(
    () => String(route.query.s || "").split(" ")[0] || undefined,
  );

  return computed<BaseTableCol<Equipment>[]>(() => {
    const records = toValue(equipment);

    return [
      { name: "name", label: t("labels.equipment.name"), sortable: true },
      {
        name: "manufacturerName",
        label: t("labels.filters.manufacturer"),
        sortable: true,
      },
      {
        name: "equipmentType",
        label: t("labels.equipment.equipmentType"),
        sortable: true,
      },
      {
        name: "itemType",
        label: t("labels.equipment.itemType"),
        sortable: true,
      },
      ...METRIC_SORTS.filter(
        (metric) =>
          metric.sort === activeSort.value ||
          records.some((record) => record[metric.field] != null),
      ).map((metric) => ({
        name: metric.sort,
        label: t(`labels.equipment.sorts.${metric.sort}`),
        sortable: true,
      })),
    ];
  });
};
