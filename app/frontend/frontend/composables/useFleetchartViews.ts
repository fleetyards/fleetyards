import { computed, ref, toValue, watch, type MaybeRefOrGetter } from "vue";
import {
  modelsFleetchartViews as fetchFleetchartViews,
  type FleetchartViewMedia,
} from "@/services/fyApi";

// The ship views a fleetchart draws with, fetched when the chart is opened rather
// than carried by every list.
//
// They are about half the bytes of a model in a list response, and most visitors
// never open the chart. Requested only while `enabled` is true, and cached by slug
// so paging back to a page already seen costs nothing.
export const useFleetchartViews = (
  slugs: MaybeRefOrGetter<string[]>,
  enabled: MaybeRefOrGetter<boolean>,
) => {
  const cache = ref<Record<string, FleetchartViewMedia>>({});
  const pending = ref(0);

  const load = async () => {
    if (!toValue(enabled)) {
      return;
    }

    const missing = toValue(slugs).filter((slug) => !cache.value[slug]);

    if (!missing.length) {
      return;
    }

    pending.value += 1;

    try {
      const views = await fetchFleetchartViews({ q: { slugIn: missing } });

      cache.value = views.reduce(
        (acc, view) => (view.media ? { ...acc, [view.slug]: view.media } : acc),
        { ...cache.value },
      );
    } catch (error) {
      // The chart draws its placeholders instead. Left uncached so reopening
      // retries rather than showing an empty chart for the rest of the session.
      console.info("fleetchart views failed", error);
    } finally {
      pending.value -= 1;
    }
  };

  watch(
    () => [toValue(enabled), toValue(slugs).join(",")],
    () => {
      void load();
    },
    { immediate: true },
  );

  const viewsFor = (slug: string): FleetchartViewMedia | undefined =>
    cache.value[slug];

  // Bumped whenever a fetch lands, so a caller that merges these into its own
  // copy of the items has something to watch.
  const revision = computed(() => Object.keys(cache.value).length);

  const loading = computed(() => pending.value > 0);

  return { viewsFor, revision, loading };
};
