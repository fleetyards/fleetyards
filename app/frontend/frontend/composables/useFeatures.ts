import { useFeatures as useFeaturesQuery } from "@/services/fyApi";

export enum QueryKeysEnum {
  FEATURES = "features",
}

export const useFeatures = () => {
  const { data: features } = useFeaturesQuery({
    query: {
      retry: false,
    },
  });

  const isFeatureEnabled = (feature: string) =>
    features.value?.includes(feature) || false;

  return {
    features,
    isFeatureEnabled,
  };
};
