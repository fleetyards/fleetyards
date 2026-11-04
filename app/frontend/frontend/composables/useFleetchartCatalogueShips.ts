import { keepPreviousData } from "@tanstack/vue-query";
import { computed, toValue, type MaybeRefOrGetter } from "vue";
import {
  catalogueEntriesFrom,
  cataloguePlacementsIn,
} from "@/frontend/components/Fleetchart/catalogueShips";
import { useModels } from "@/services/fyApi";
import { useFleetchartStore } from "@/shared/stores/fleetchart";

// The most models one request returns, and more than a chart is likely to try out.
const MAX_MODELS = "240";

// A chart's placements only name the models of its catalogue ships, so the models
// themselves are fetched for as long as a free arrangement is showing.
export const useFleetchartCatalogueShips = (
  namespace: string,
  enabled: MaybeRefOrGetter<boolean>,
) => {
  const fleetchartStore = useFleetchartStore();

  const placed = computed(() =>
    toValue(enabled)
      ? cataloguePlacementsIn(fleetchartStore.fleetchartPlacements(namespace))
      : [],
  );

  const modelIds = computed(() =>
    [...new Set(placed.value.map(({ modelId }) => modelId))].sort(),
  );

  // Adding a ship must not take the ones already drawn away until it has arrived.
  const { data, isPending } = useModels(
    computed(() => ({ perPage: MAX_MODELS, q: { idIn: modelIds.value } })),
    {
      query: {
        enabled: computed(() => modelIds.value.length > 0),
        placeholderData: keepPreviousData,
      },
    },
  );

  const entries = computed(() =>
    catalogueEntriesFrom(placed.value, data.value?.items ?? []),
  );

  const loaded = computed(() => !modelIds.value.length || !isPending.value);

  return { entries, loaded };
};
