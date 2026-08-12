import { computed, ref, toValue, watch, type MaybeRefOrGetter } from "vue";
import {
  HardpointSourceEnum,
  modelHardpoints as fetchModelHardpoints,
  type Hardpoint,
  type Model,
} from "@/services/fyApi";

// Hardpoints for every compared ship, fetched once and cached by slug: adding a
// fourth ship must not refetch the three already on screen. The compare page owns
// this so the Combat, Defense and Hardpoints sections share one set of requests
// instead of each fetching the whole set again.
export const useCompareHardpoints = (models: MaybeRefOrGetter<Model[]>) => {
  const cache = ref<Record<string, Hardpoint[]>>({});
  const pendingCount = ref(0);

  const sourceFor = (model: Model) =>
    model.inGame
      ? HardpointSourceEnum.GAME_FILES
      : HardpointSourceEnum.SHIP_MATRIX;

  const fetchFor = async (model: Model) => {
    try {
      const hardpoints = (await fetchModelHardpoints(model.slug, {
        source: sourceFor(model),
      })) as Hardpoint[];

      cache.value = { ...cache.value, [model.slug]: hardpoints };
    } catch (error) {
      // Left uncached on purpose, so the next change to the compare set retries
      // instead of locking the ship into an empty loadout forever.
      console.info("compare hardpoints failed", model.slug, error);
    }
  };

  const load = async () => {
    const missing = toValue(models).filter((model) => !cache.value[model.slug]);

    if (!missing.length) {
      return;
    }

    pendingCount.value += missing.length;

    try {
      await Promise.all(missing.map(fetchFor));
    } finally {
      pendingCount.value -= missing.length;
    }
  };

  watch(
    () =>
      toValue(models)
        .map((model) => model.slug)
        .join(","),
    () => {
      void load();
    },
    { immediate: true },
  );

  const hardpointsFor = (model: Model): Hardpoint[] =>
    cache.value[model.slug] || [];

  const loading = computed(() => pendingCount.value > 0);

  return { hardpointsFor, loading };
};
