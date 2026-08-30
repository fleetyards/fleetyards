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

  const from = async (model: Model, source: HardpointSourceEnum) =>
    (await fetchModelHardpoints(model.slug, { source })) as Hardpoint[];

  // Game files first, whatever `inGame` says. That flag asks whether the build we are
  // on describes the ship, which is not the same question as whether an export of its
  // loadout exists -- and the ship-matrix set answers with `component: null` on every
  // entry, so preferring it leaves Combat, Defense and Loadout with nothing to compare
  // and all three drop out of the table silently.
  //
  // The fallback costs a second request only for a ship the files do not fit, since a
  // fitted set is recognisable from the first response.
  const fetchFor = async (model: Model) => {
    try {
      const fitted = await from(model, HardpointSourceEnum.GAME_FILES);

      const hardpoints = fitted.some((hardpoint) => hardpoint.component)
        ? fitted
        : await from(model, HardpointSourceEnum.SHIP_MATRIX);

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
