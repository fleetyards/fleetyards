import { computed, ref, toValue, watch, type MaybeRefOrGetter } from "vue";
import { model as fetchModel, type ModelExtended } from "@/services/fyApi";
import type { AsyncStatus } from "@/shared/components/AsyncData.types";

// The compared ships, fetched one detail request each rather than through the
// models index.
//
// Compare reads far more of a ship than any list does -- the exotic metrics, and
// the side and top views -- and asking the index for them means every ships list
// and every hangar page carries those fields too, for rows nobody compares. The
// detail endpoint already returns a superset, so this is the same data from the
// place that is meant to serve it.
//
// Cached by slug for the same reason as `useCompareHardpoints`: adding a fourth
// ship must not refetch the three already on screen.
export const useCompareModels = (slugs: MaybeRefOrGetter<string[]>) => {
  const cache = ref<Record<string, ModelExtended>>({});
  const pendingCount = ref(0);
  const failure = ref<Error | null>(null);

  const fetchFor = async (slug: string) => {
    try {
      // Awaited into a local first: spreading the cache in the same expression
      // reads it before the request resolves, so parallel fetches each write back
      // a snapshot taken before any of them landed and only the last ship survives.
      const model = await fetchModel(slug);

      cache.value = { ...cache.value, [slug]: model };
    } catch (error) {
      // Left uncached on purpose, so changing the compare set retries instead of
      // leaving the ship missing from the table forever. Reported through
      // `asyncStatus` so a slug that does not resolve reaches the error slot
      // rather than showing an empty table.
      failure.value = error instanceof Error ? error : new Error(String(error));
    }
  };

  const load = async () => {
    const missing = toValue(slugs).filter((slug) => !cache.value[slug]);

    if (!missing.length) {
      return;
    }

    failure.value = null;
    pendingCount.value += missing.length;

    try {
      await Promise.all(missing.map(fetchFor));
    } finally {
      pendingCount.value -= missing.length;
    }
  };

  watch(
    () => toValue(slugs).join(","),
    () => {
      void load();
    },
    { immediate: true },
  );

  // In the order the compare set names them, and skipping any whose request
  // failed, so the table renders what did arrive.
  const models = computed(() =>
    toValue(slugs)
      .map((slug) => cache.value[slug])
      .filter((model): model is ModelExtended => Boolean(model)),
  );

  const loading = computed(() => pendingCount.value > 0);

  // Drops the cache, so this is a real reload rather than the incremental fill
  // the watcher does. Nothing calls it today; it is here because `AsyncStatus`
  // offers it and an error slot may want to retry.
  const refetch = async () => {
    cache.value = {};

    await load();
  };

  // Filling in a ship beside ones already on screen, rather than the first load
  // with nothing to show yet.
  const incremental = computed(() => loading.value && models.value.length > 0);

  // Shaped for `AsyncData`, which reads a fetch as a refetch — and so keeps its
  // resolved slot mounted — only when `isRefetching` says so. Reporting the
  // incremental fill as a plain load swapped the whole table for a spinner and
  // remounted it, so adding a fourth ship threw away the scroll position, the
  // pinned header and every collapsed section.
  const asyncStatus: AsyncStatus = {
    fetchStatus: computed(() => (loading.value ? "fetching" : "idle")),
    isError: computed(() => Boolean(failure.value)),
    isPending: computed(() => loading.value && !incremental.value),
    isLoading: computed(() => loading.value && !incremental.value),
    isFetching: loading,
    isRefetching: incremental,
    // Wrapped because the slot expects a void return, and handing it a promise
    // leaves a rejection with nobody to catch it.
    refetch: () => {
      void refetch();
    },
    error: failure,
  };

  return { models, loading, refetch, asyncStatus };
};
