import { useApiClient } from "@/frontend/composables/useApiClient";
import { useQuery, useQueryClient } from "@tanstack/vue-query";

export enum QueryKeysEnum {
  FEATURES = "features",
}

export const useFeatures = () => {
  const { features: featuresService } = useApiClient();

  const queryClient = useQueryClient();

  const { data: features } = useQuery(
    {
      queryKey: [QueryKeysEnum.FEATURES],
      queryFn: () => featuresService.features(),
      retry: false,
    },
    queryClient,
  );

  const isFeatureEnabled = (feature: string) =>
    features.value?.includes(feature) || false;

  return {
    features,
    isFeatureEnabled,
  };
};
