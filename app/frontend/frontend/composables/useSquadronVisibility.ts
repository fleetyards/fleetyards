import { useFeatures } from "@/frontend/composables/useFeatures";
import {
  FeatureFlagName,
  type Fleet,
  type FilterOption,
} from "@/services/fyApi";

/*
 * The squadron-only choice in a visibility select, offered only where a fleet
 * has squadrons at all. Offered without them, the squadron picker it opens has
 * nothing in it and the save is refused. A record already held to squadrons
 * keeps the choice, so its form does not open on a blank select.
 */
export const useSquadronVisibility = (
  fleet: MaybeRefOrGetter<Fleet>,
  squadronValue: string,
  current: MaybeRefOrGetter<string | null | undefined>,
) => {
  const { isFleetFeatureEnabled } = useFeatures();

  const squadronsEnabled = computed(() =>
    isFleetFeatureEnabled(toValue(fleet), FeatureFlagName.FLEET_SQUADRONS),
  );

  const withSquadronChoice = (options: FilterOption[]) =>
    options.filter(
      (option) =>
        option.value !== squadronValue ||
        squadronsEnabled.value ||
        toValue(current) === squadronValue,
    );

  return { squadronsEnabled, withSquadronChoice };
};
