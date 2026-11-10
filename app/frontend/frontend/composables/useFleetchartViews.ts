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
// The slugs travel in the query string, which a whole fleet's models would push
// past what a server accepts.
const SLUGS_PER_REQUEST = 100;

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

    const missing = [...new Set(toValue(slugs))].filter(
      (slug) => !cache.value[slug],
    );

    if (!missing.length) {
      return;
    }

    pending.value += 1;

    try {
      const chunks = Array.from(
        { length: Math.ceil(missing.length / SLUGS_PER_REQUEST) },
        (_, index) =>
          missing.slice(
            index * SLUGS_PER_REQUEST,
            (index + 1) * SLUGS_PER_REQUEST,
          ),
      );
      const results = await Promise.allSettled(
        chunks.map((slugIn) => fetchFleetchartViews({ q: { slugIn } })),
      );

      // A model without views is remembered as having none, so a changed list
      // does not ask for it again; a failed chunk stays uncached to be retried.
      const next = { ...cache.value };

      results.forEach((result, index) => {
        if (result.status === "rejected") {
          console.info("fleetchart views failed", result.reason);

          return;
        }

        const found = new Map(
          result.value.map((view) => [view.slug, view.media]),
        );

        chunks[index].forEach((slug) => {
          next[slug] = found.get(slug) ?? {};
        });
      });

      cache.value = next;
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
