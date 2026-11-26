import { useModelLoadoutPreview } from "@/services/fyApi";
import { useModelsStore } from "@/frontend/stores/models";

// The 3D view's loadout holo: whether the ship has a hull holo to draw its
// loadout on, asked only once the view is open, and the switch to it. It and
// the textured holo are two looks at the ship, so one turns the other off.
export const useLoadoutHolo = (
  modelSlug: MaybeRefOrGetter<string | undefined>,
  wanted: MaybeRefOrGetter<boolean>,
  texturedHolo: Ref<boolean>,
) => {
  const enabled = computed(() => !!toValue(modelSlug) && toValue(wanted));

  const { data: preview } = useModelLoadoutPreview(
    () => toValue(modelSlug) ?? "",
    { query: { enabled } },
  );

  const loadoutHoloAvailable = computed(
    () => enabled.value && !!preview.value?.holoHull?.url,
  );

  const modelsStore = useModelsStore();

  const loadoutHolo = computed({
    get: () => modelsStore.loadoutHolo,
    set: (shown: boolean) => {
      modelsStore.loadoutHolo = shown;
    },
  });

  const loadoutHoloShown = computed(
    () => loadoutHoloAvailable.value && loadoutHolo.value,
  );

  const toggleLoadoutHolo = () => {
    loadoutHolo.value = !loadoutHolo.value;
    if (loadoutHolo.value) texturedHolo.value = false;
  };

  watch(texturedHolo, (textured) => {
    if (textured) loadoutHolo.value = false;
  });

  return {
    loadoutHolo,
    loadoutHoloAvailable,
    loadoutHoloShown,
    toggleLoadoutHolo,
  };
};
