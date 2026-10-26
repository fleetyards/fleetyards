import { useI18n } from "@/shared/composables/useI18n";
import { type Model } from "@/services/fyAdminApi";
import {
  useModelsStore,
  AdminModelSortFieldsEnum,
} from "@/admin/stores/models";
import {
  useSelectableSortFields,
  type SelectableSortFieldsOptions,
} from "@/frontend/composables/useSelectableSortFields";

export const useAdminModelSortFields = (
  options: SelectableSortFieldsOptions = {},
) => {
  const { t } = useI18n();

  const modelsStore = useModelsStore();

  return useSelectableSortFields<Model>(
    () =>
      Object.values(AdminModelSortFieldsEnum).map((name) => ({
        name,
        label:
          name === AdminModelSortFieldsEnum.NAME
            ? t("labels.vehicle.name")
            : t(`labels.models.table.columns.${name}`),
      })),
    () => modelsStore.sortFields,
    options,
  );
};
