import { computed, toValue, type MaybeRefOrGetter } from "vue";
import { useRoute, useRouter } from "vue-router";
import { usePaginationStore } from "@/shared/stores/pagination";
import { shortUrl } from "@/frontend/utils/shortUrl";

// The current page with the chart open: filters, sort and page live in the
// query, the page size is added so the page holds the same items, and
// `fleetchart` opens the chart on mount. A page with a short-domain path
// carries the same query on the short link.
export const useFleetchartShareUrl = (
  shortPath?: MaybeRefOrGetter<string | undefined>,
) => {
  const route = useRoute();
  const router = useRouter();
  const paginationStore = usePaginationStore();

  return computed(() => {
    const perPage =
      route.query.perPage ??
      paginationStore.findByKey((route.name as string) || "");

    const { href } = router.resolve({
      path: route.path,
      query: {
        ...route.query,
        ...(perPage ? { perPage: String(perPage) } : {}),
        fleetchart: "true",
      },
    });

    const url = new URL(href, window.location.origin);
    const path = toValue(shortPath);

    return (path && shortUrl(path, url.search)) || url.href;
  });
};
