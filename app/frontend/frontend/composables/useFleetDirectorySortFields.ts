import { useI18n } from "@/shared/composables/useI18n";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import { type FleetDirectoryEntry } from "@/services/fyApi";

export const useFleetDirectorySortFields = () => {
  const { t } = useI18n();

  return computed<BaseTableCol<FleetDirectoryEntry>[]>(() => [
    {
      name: "memberCount",
      label: t("labels.fleetDirectory.memberCount"),
      sortable: true,
    },
    { name: "name", label: t("labels.fleetDirectory.name"), sortable: true },
    {
      name: "createdAt",
      label: t("labels.fleetDirectory.createdAt"),
      sortable: true,
    },
  ]);
};
