import { useI18n } from "@/shared/composables/useI18n";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import { type Blueprint } from "@/services/fyApi";

/**
 * The sorts the blueprint catalogue offers above its rows.
 *
 * Only the two the API actually accepts. `Blueprint::ALLOWED_SORTING_PARAMS`
 * is the whitelist the controller sorts by, and offering a column it does not
 * name would send a request that comes back 400 rather than reordered.
 */
export const useBlueprintSortFields = () => {
  const { t } = useI18n();

  return computed<BaseTableCol<Blueprint>[]>(() => [
    { name: "name", label: t("labels.blueprint.name"), sortable: true },
    {
      name: "craftTime",
      label: t("labels.blueprint.craftTime"),
      sortable: true,
    },
  ]);
};
