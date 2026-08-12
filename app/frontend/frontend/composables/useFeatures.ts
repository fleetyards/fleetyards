import {
  useFeatures as useFeaturesQuery,
  type FeatureFlagName,
} from "@/services/fyApi";
import { usePrefetch } from "@/shared/composables/usePrefetch";

export const useFeatures = () => {
  const { fetchData } = usePrefetch();

  const { data: features } = useFeaturesQuery({
    query: {
      retry: false,
      initialData: fetchData("features"),
      staleTime: 1000,
    },
  });

  // FeatureFlagName comes from config/feature_flags.yml, so a flag that is not
  // declared there — or a typo — fails to compile rather than silently
  // evaluating false forever.
  const isFeatureEnabled = (feature: FeatureFlagName) =>
    features.value?.includes(feature) || false;

  return {
    features,
    isFeatureEnabled,
  };
};
