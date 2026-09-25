import { type FilterOption } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useVehicleSortFields } from "@/frontend/composables/useVehicleSortFields";

/**
 * The orders a hangar can open in, for every place the owner picks one.
 *
 * The first is the standard: no stored order, so the server leads with the
 * flagship and then sorts by name, which none of the single sorts reproduces.
 *
 * The custom order only runs one way: it is the order the ships were dragged
 * into, and reading it backwards is not an order anybody arranged.
 */
export const useHangarDefaultSortOptions = () => {
  const { t } = useI18n();

  const sortFields = useVehicleSortFields({ rank: true });

  return computed<FilterOption[]>(() => [
    { value: null, label: t("labels.user.hangarDefaultSortOptions.standard") },
    ...sortFields.value.flatMap(({ name, label }) => {
      if (name === "rank") {
        return [{ value: "rank asc", label }];
      }

      return (["asc", "desc"] as const).map((direction) => ({
        value: `${String(name)} ${direction}`,
        label: t(`labels.user.hangarDefaultSortOptions.${direction}`, {
          field: label,
        }),
      }));
    }),
  ]);
};
