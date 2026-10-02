import { useI18n } from "@/shared/composables/useI18n";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import { type Location } from "@/services/fyApi";

// The two `Location::ALLOWED_SORTING_PARAMS` names. A column it does not name
// would send a request that comes back 400 rather than reordered.
export const useLocationSortFields = () => {
  const { t } = useI18n();

  return computed<BaseTableCol<Location>[]>(() => [
    { name: "name", label: t("labels.location.name"), sortable: true },
    { name: "kind", label: t("labels.location.kind"), sortable: true },
  ]);
};
