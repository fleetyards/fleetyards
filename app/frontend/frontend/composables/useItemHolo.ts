import { FeatureFlagName, type MediaFile } from "@/services/fyApi";
import { useFeatures } from "@/frontend/composables/useFeatures";

type Holos = {
  holo?: MediaFile | null;
  holoTextured?: MediaFile | null;
};

type Options = {
  textured?: boolean;
  // Whether the textured holo may be loaded where it is shown.
  canLoad?: (file: MediaFile) => boolean;
};

// The holo a component or piece of equipment is shown by: the plain one, or
// its painted export.
export const useItemHolo = (
  holos: MaybeRefOrGetter<Holos>,
  { textured = false, canLoad = () => true }: Options = {},
) => {
  const { isFeatureEnabled } = useFeatures();

  const texturedHoloAvailable = computed(() => {
    const { holo, holoTextured } = toValue(holos);

    return (
      isFeatureEnabled(FeatureFlagName.ITEM_HOLO_TEXTURED) &&
      !!holo?.url &&
      !!holoTextured?.url &&
      canLoad(holoTextured)
    );
  });

  const texturedHolo = ref(textured);

  const toggleTexturedHolo = () => {
    texturedHolo.value = !texturedHolo.value;
  };

  const holoModel = computed(() => {
    const isTextured = texturedHoloAvailable.value && texturedHolo.value;
    const { holo, holoTextured } = toValue(holos);
    const file = isTextured ? holoTextured : holo;

    return file?.url
      ? { path: file.url, size: file.size ?? undefined, textured: isTextured }
      : undefined;
  });

  return { texturedHolo, texturedHoloAvailable, toggleTexturedHolo, holoModel };
};
