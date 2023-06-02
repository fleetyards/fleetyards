import featuresCollection from "@/frontend/api/collections/Features";

export const useFeatures = () => {
  const features = ref<string[]>([]);

  onMounted(() => {
    fetch();
  });

  const fetch = async () => {
    features.value = await featuresCollection.findAll();
  };

  const isFeatureEnabled = (feature: string) =>
    features.value.includes(feature);

  return {
    features,
    isFeatureEnabled,
  };
};
