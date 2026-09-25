import { useI18n } from "@/shared/composables/useI18n";
import { type Vehicle } from "@/services/fyApi";
import { useFleetStore, FleetSortFieldsEnum } from "@/frontend/stores/fleet";
import {
  useSelectableSortFields,
  type SelectableSortFieldsOptions,
} from "@/frontend/composables/useSelectableSortFields";

const fieldLabel = (
  t: ReturnType<typeof useI18n>["t"],
  name: FleetSortFieldsEnum,
) => {
  switch (name) {
    case FleetSortFieldsEnum.NAME:
      return t("labels.vehicle.name");
    case FleetSortFieldsEnum.COUNT:
      return t("labels.fleetTable.columns.vehiclesCount");
    default:
      return t(`labels.hangarTable.columns.${name}`);
  }
};

// Labelled like the hangar's sorts: the fleet table has no focus column to
// borrow a label from, and the two lists sort by the same ship figures.
//
// The count only exists once the list is grouped by ship, so an ungrouped list
// never offers it -- not even as the sort a link arrived with, which the API
// answers with the default.
export const useFleetSortFields = (
  options: SelectableSortFieldsOptions = {},
) => {
  const { t } = useI18n();

  const fleetStore = useFleetStore();

  return useSelectableSortFields<Vehicle>(
    () =>
      Object.values(FleetSortFieldsEnum)
        .filter(
          (name) =>
            options.all ||
            fleetStore.grouped ||
            name !== FleetSortFieldsEnum.COUNT,
        )
        .map((name) => ({ name, label: fieldLabel(t, name) })),
    () => fleetStore.sortFields,
    options,
  );
};
