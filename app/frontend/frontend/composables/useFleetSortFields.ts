import { useI18n } from "@/shared/composables/useI18n";
import { type Vehicle } from "@/services/fyApi";
import { useFleetStore, FleetSortFieldsEnum } from "@/frontend/stores/fleet";
import {
  useSelectableSortFields,
  type SelectableSortFieldsOptions,
} from "@/frontend/composables/useSelectableSortFields";

// Labelled like the hangar's sorts: the fleet table has no focus column to
// borrow a label from, and the two lists sort by the same ship figures.
export const useFleetSortFields = (
  options: SelectableSortFieldsOptions = {},
) => {
  const { t } = useI18n();

  const fleetStore = useFleetStore();

  return useSelectableSortFields<Vehicle>(
    () =>
      Object.values(FleetSortFieldsEnum).map((name) => ({
        name,
        label:
          name === FleetSortFieldsEnum.NAME
            ? t("labels.vehicle.name")
            : t(`labels.hangarTable.columns.${name}`),
      })),
    () => fleetStore.sortFields,
    options,
  );
};
