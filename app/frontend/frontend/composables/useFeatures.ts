import {
  getFeaturesQueryOptions,
  useFeatures as useFeaturesQuery,
  type FeatureFlagName,
  type Fleet,
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

  // Mirrors the backend gate, `Flipper.enabled?(flag, user, fleet)`: on for the
  // viewer or on for this fleet. Only for *this* fleet — the viewer's flag list
  // used to fold in every fleet they belong to, which showed one fleet's
  // features on every other fleet's page.
  const isFleetFeatureEnabled = (
    fleet: Pick<Fleet, "features"> | undefined | null,
    feature: FeatureFlagName,
  ) => isFeatureEnabled(feature) || fleet?.features?.includes(feature) || false;

  return {
    features,
    isFeatureEnabled,
    isFleetFeatureEnabled,
  };
};
