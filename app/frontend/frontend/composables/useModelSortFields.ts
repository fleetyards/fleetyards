import { useI18n } from "@/shared/composables/useI18n";
import { type Model } from "@/services/fyApi";
import { useModelsStore, ModelSortFieldsEnum } from "@/frontend/stores/models";
import {
  useSelectableSortFields,
  type SelectableSortFieldsOptions,
} from "@/frontend/composables/useSelectableSortFields";

// The labels are the ships table's own, so both views name a sort the same way.
export const useModelSortFields = (
  options: SelectableSortFieldsOptions = {},
) => {
  const { t } = useI18n();

  const modelsStore = useModelsStore();

  return useSelectableSortFields<Model>(
    () =>
      Object.values(ModelSortFieldsEnum).map((name) => ({
        name,
        label:
          name === ModelSortFieldsEnum.NAME
            ? t("labels.vehicle.name")
            : t(`labels.models.table.columns.${name}`),
      })),
    () => modelsStore.sortFields,
    options,
  );
};
