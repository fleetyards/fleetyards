import type { MaybeRefOrGetter } from "vue";
import { model as fetchModel, type ModelExtended } from "@/services/fyApi";
import { useCompareItems } from "@/frontend/composables/useCompareItems";

// The compared ships, fetched one detail request each rather than through the
// models index.
//
// Compare reads far more of a ship than any list does -- the exotic metrics, and
// the side and top views -- and asking the index for them means every ships list
// and every hangar page carries those fields too, for rows nobody compares. The
// detail endpoint already returns a superset, so this is the same data from the
// place that is meant to serve it.
export const useCompareModels = (slugs: MaybeRefOrGetter<string[]>) => {
  const { items, ...rest } = useCompareItems<ModelExtended>(slugs, fetchModel);

  return { models: items, ...rest };
};
