import { useI18n } from "@/shared/composables/useI18n";
import { type Vehicle } from "@/services/fyApi";
import { useHangarStore, HangarSortFieldsEnum } from "@/frontend/stores/hangar";
import {
  useSelectableSortFields,
  type SelectableSortFieldsOptions,
} from "@/frontend/composables/useSelectableSortFields";

export const useHangarSortFields = (
  options: SelectableSortFieldsOptions = {},
) => {
  const { t } = useI18n();

  const hangarStore = useHangarStore();

  const label = (field: HangarSortFieldsEnum) => {
    if (field === HangarSortFieldsEnum.RANK) {
      return t("labels.vehicle.customOrder");
    }

    if (field === HangarSortFieldsEnum.NAME) {
      return t("labels.vehicle.name");
    }

    return t(`labels.hangarTable.columns.${field}`);
  };

  return useSelectableSortFields<Vehicle>(
    () =>
      Object.values(HangarSortFieldsEnum).map((name) => ({
        name,
        label: label(name),
      })),
    () => hangarStore.sortFields,
    options,
  );
};
