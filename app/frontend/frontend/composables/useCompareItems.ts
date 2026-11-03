import {
  computed,
  ref,
  shallowRef,
  toValue,
  watch,
  type MaybeRefOrGetter,
} from "vue";
import type { AsyncStatus } from "@/shared/components/AsyncData.types";

type Named = { name: string };

// The compared subjects, fetched one detail request each.
//
// Cached by slug for the same reason as `useCompareHardpoints`: adding a fourth
// item must not refetch the three already on screen.
export const useCompareItems = <T extends Named>(
  slugs: MaybeRefOrGetter<string[]>,
  fetchItem: (slug: string) => Promise<T>,
) => {
  // Not a `ref`: unwrapping would turn `T` into `UnwrapRef<T>`, which a generic
  // cannot be narrowed back from.
  const cache = shallowRef<Record<string, T>>({});
  const pendingCount = ref(0);
  const failure = ref<Error | null>(null);

  const fetchFor = async (slug: string) => {
    try {
      // Awaited into a local first: spreading the cache in the same expression
      // reads it before the request resolves, so parallel fetches each write back
      // a snapshot taken before any of them landed and only the last item survives.
      const item = await fetchItem(slug);

      cache.value = { ...cache.value, [slug]: item };
    } catch (error) {
      // Left uncached on purpose, so changing the compare set retries instead of
      // leaving the item missing from the table forever. Reported through
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

  // By name, and skipping any whose request failed so the table renders what did
  // arrive. Not in the order the compare set names them: that is an order of slugs,
  // which begin with a manufacturer code, so the columns came out grouped by a
  // prefix that is nowhere on screen and read as no order at all.
  const items = computed(() =>
    toValue(slugs)
      .map((slug) => cache.value[slug])
      .filter((item): item is T => Boolean(item))
      // Numeric so the 100i sorts before the 125a rather than between them.
      .sort((a, b) =>
        a.name.localeCompare(b.name, undefined, { numeric: true }),
      ),
  );

  const loading = computed(() => pendingCount.value > 0);

  // Drops the cache, so this is a real reload rather than the incremental fill
  // the watcher does. Nothing calls it today; it is here because `AsyncStatus`
  // offers it and an error slot may want to retry.
  const refetch = async () => {
    cache.value = {};

    await load();
  };

  // Filling in an item beside ones already on screen, rather than the first load
  // with nothing to show yet.
  const incremental = computed(() => loading.value && items.value.length > 0);

  // Shaped for `AsyncData`, which reads a fetch as a refetch — and so keeps its
  // resolved slot mounted — only when `isRefetching` says so. Reporting the
  // incremental fill as a plain load swapped the whole table for a spinner and
  // remounted it, so adding a fourth item threw away the scroll position, the
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

  return { items, loading, refetch, asyncStatus };
};
