import { type MaybeRefOrGetter } from "vue";
import { useQueryClient } from "@tanstack/vue-query";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  getAdminFeaturesQueryKey,
  enableAdminFeature,
  disableAdminFeature,
  enableAdminFeatureActor,
  disableAdminFeatureActor,
  enableAdminFeatureGroup,
  disableAdminFeatureGroup,
  enableAdminFeaturePercentageOfActors,
  enableAdminFeaturePercentageOfTime,
  toggleAdminFeatureUserSelfService,
  toggleAdminFeatureFleetSelfService,
} from "@/services/fyAdminApi";

export type FeatureActorType = "User" | "Fleet";

// Every gate change for one flag, each reporting itself and refreshing the
// list, the flag and its history at once: they share the `features` key prefix.
export const useFeatureActions = (name: MaybeRefOrGetter<string>) => {
  const { t } = useI18n();
  const { displaySuccess, displayAlert } = useAppNotifications();
  const queryClient = useQueryClient();

  const busy = ref(false);

  const run = async (action: () => Promise<unknown>, message: string) => {
    busy.value = true;

    try {
      await action();
      await queryClient.invalidateQueries({
        queryKey: getAdminFeaturesQueryKey(),
      });
      displaySuccess({ text: message });
      return true;
    } catch {
      displayAlert({ text: t("messages.features.error") });
      return false;
    } finally {
      busy.value = false;
    }
  };

  const feature = () => toValue(name);

  return {
    busy,
    setGlobal: (on: boolean) =>
      run(
        () =>
          on ? enableAdminFeature(feature()) : disableAdminFeature(feature()),
        t("messages.features.updated"),
      ),
    addActor: (type: FeatureActorType, id: string) =>
      run(
        () =>
          enableAdminFeatureActor(feature(), {
            actor_type: type,
            actor_id: id,
          }),
        t("messages.features.actorAdded"),
      ),
    removeActor: (type: FeatureActorType, id: string) =>
      run(
        () =>
          disableAdminFeatureActor(feature(), {
            actor_type: type,
            actor_id: id,
          }),
        t("messages.features.actorRemoved"),
      ),
    addGroup: (group: string) =>
      run(
        () => enableAdminFeatureGroup(feature(), { group }),
        t("messages.features.groupAdded"),
      ),
    removeGroup: (group: string) =>
      run(
        () => disableAdminFeatureGroup(feature(), { group }),
        t("messages.features.groupRemoved"),
      ),
    setPercentageOfActors: (percentage: number) =>
      run(
        () => enableAdminFeaturePercentageOfActors(feature(), { percentage }),
        t("messages.features.updated"),
      ),
    setPercentageOfTime: (percentage: number) =>
      run(
        () => enableAdminFeaturePercentageOfTime(feature(), { percentage }),
        t("messages.features.updated"),
      ),
    toggleUserSelfService: () =>
      run(
        () => toggleAdminFeatureUserSelfService(feature()),
        t("messages.features.updated"),
      ),
    toggleFleetSelfService: () =>
      run(
        () => toggleAdminFeatureFleetSelfService(feature()),
        t("messages.features.updated"),
      ),
  };
};
