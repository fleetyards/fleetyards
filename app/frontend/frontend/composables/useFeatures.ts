import {
  getFeaturesQueryOptions,
  useFeatures as useFeaturesQuery,
  type FeatureFlagName,
} from "@/services/fyApi";
import { usePrefetch } from "@/shared/composables/usePrefetch";

// fetchData consumes the prefetched payload, so whichever of the composable and
// the router's feature guard runs first seeds the cache and the other finds the
// data already there.
const featuresQueryConfig = () => {
  const { fetchData } = usePrefetch();

  return {
    retry: false,
    initialData: fetchData<string[]>("features"),
    staleTime: 1000,
  };
};

// The guard reads the flags outside a setup context, so it cannot use the
// composable — it goes through the query client with these same options.
export const featuresQueryOptions = () =>
  getFeaturesQueryOptions({ query: featuresQueryConfig() });

export const useFeatures = () => {
  const { data: features } = useFeaturesQuery({
    query: featuresQueryConfig(),
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
