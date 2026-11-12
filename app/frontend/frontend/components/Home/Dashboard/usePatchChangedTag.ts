import { type Vehicle, useMyPatchChanges } from "@/services/fyApi";
import { liveQuery } from "@/shared/components/Dashboard/liveQuery";
import { useI18n } from "@/shared/composables/useI18n";

// Most builds leave a pilot's ships alone, so the patch has no panel of its
// own: a ship it did change carries a tag, and otherwise nothing says so.
export const usePatchChangedTag = () => {
  const { t } = useI18n();

  const { data } = useMyPatchChanges({ query: liveQuery });

  const changedModelIds = computed(
    () => new Set(data.value?.ownedModelIds || []),
  );

  return (vehicle: Vehicle) =>
    data.value && changedModelIds.value.has(vehicle.model.id)
      ? t("home.dashboard.ships.changedIn", {
          version: data.value.version.split("-")[0],
        })
      : undefined;
};
