import { FeatureFlagName, type MediaFile } from "@/services/fyApi";
import { useFeatures } from "@/frontend/composables/useFeatures";

type Holos = {
  holo?: MediaFile | null;
  holoTextured?: MediaFile | null;
};

type Options = {
  // Whether the textured holo may be loaded where it is shown.
  canLoad?: (file: MediaFile) => boolean;
};

// The holo a component or piece of equipment is shown by: its painted export
// where there is one that loads, the plain one otherwise.
export const useItemHolo = (
  holos: MaybeRefOrGetter<Holos>,
  { canLoad = () => true }: Options = {},
) => {
  const { isFeatureEnabled } = useFeatures();

  const texturedHoloFailed = ref(false);

  watch(
    () => toValue(holos).holoTextured?.url,
    () => {
      texturedHoloFailed.value = false;
    },
  );

  const holoModel = computed(() => {
    const { holo, holoTextured } = toValue(holos);
    const isTextured =
      isFeatureEnabled(FeatureFlagName.ITEM_HOLO_TEXTURED) &&
      !!holo?.url &&
      !!holoTextured?.url &&
      canLoad(holoTextured) &&
      !texturedHoloFailed.value;
    const file = isTextured ? holoTextured : holo;

    return file?.url
      ? { path: file.url, size: file.size ?? undefined, textured: isTextured }
      : undefined;
  });

  // Falls back to the plain holo, and says whether there was one to fall back
  // from.
  const fallBackToPlainHolo = () => {
    if (!holoModel.value?.textured) return false;

    texturedHoloFailed.value = true;

    return true;
  };

  return { holoModel, fallBackToPlainHolo };
};
