import { computed } from "vue";
import { useRoute, useRouter } from "vue-router";
import { usePaginationStore } from "@/shared/stores/pagination";

// The current page with the chart open: filters, sort and page live in the
// query, the page size is added so the page holds the same items, and
// `fleetchart` opens the chart on mount.
export const useFleetchartShareUrl = () => {
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

    return `${window.location.origin}${href}`;
  });
};
