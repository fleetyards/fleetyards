import { useFeatures as useFeaturesQuery } from "@/services/fyApi";
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

  const isFeatureEnabled = (feature: string) =>
    features.value?.includes(feature) || false;

  return {
    features,
    isFeatureEnabled,
  };
};
