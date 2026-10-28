import {
  FeatureFlagName,
  RaffleStatusEnum,
  useCurrentRaffle,
} from "@/services/fyApi";
import { useFeatures } from "@/frontend/composables/useFeatures";

// The raffle the homepage points at: the current one while it can still be
// entered or is about to open. A drawn raffle is news on its own page, not
// on the homepage.
export const useHomeRaffle = () => {
  const { isFeatureEnabled } = useFeatures();

  const enabled = computed(() => isFeatureEnabled(FeatureFlagName.RAFFLES));

  const { data } = useCurrentRaffle({ query: { enabled } });

  return computed(() => {
    const raffle = data.value;
    if (!enabled.value || !raffle) return undefined;

    const shown: RaffleStatusEnum[] = [
      RaffleStatusEnum.OPEN,
      RaffleStatusEnum.UPCOMING,
    ];

    return shown.includes(raffle.status) ? raffle : undefined;
  });
};
