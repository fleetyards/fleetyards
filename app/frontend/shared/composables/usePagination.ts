import { useRoute, useRouter, type LocationQueryValue } from "vue-router";
import { usePaginationStore } from "@/shared/stores/pagination";
import { useQueryClient } from "@tanstack/vue-query";
import type { QueryKey } from "@tanstack/vue-query";
import type { MaybeRef } from "vue";
import { errorCodeFrom } from "@/shared/utils/ErrorTypes";

// The sizes any list can offer, as `PageSizes::STEPS` in the API declares them.
// A size off this set, saved or linked from before, fills no grid row evenly.
const PAGE_SIZES = ["12", "24", "48", "96", "144", "240", "all"];

const isPageSize = (size: string | number | null | undefined) =>
  size !== undefined && size !== null && PAGE_SIZES.includes(String(size));

const firstOf = (
  value: LocationQueryValue | LocationQueryValue[] | undefined,
): LocationQueryValue | undefined => (Array.isArray(value) ? value[0] : value);

export const usePagination = (
  queryKey: MaybeRef<QueryKey | string | undefined>,
) => {
  const paginationStore = usePaginationStore();

  const route = useRoute();

  const key = computed(() => {
    return (route.name as string) || "";
  });

  const router = useRouter();

  const linkedPerPage = computed(() => firstOf(route.query.perPage));

  const savedPerPage = computed(() => paginationStore.findByKey(key.value));

  // A shared link carries the sender's page size, so it shows the same items
  // without overwriting the size this visitor keeps for the list. A size that
  // is no longer offered is never requested: the list falls back to the saved
  // size, then to its default.
  const perPage = computed(() => {
    if (isPageSize(linkedPerPage.value)) {
      return String(linkedPerPage.value);
    }

    if (isPageSize(savedPerPage.value)) {
      return String(savedPerPage.value);
    }

    return undefined;
  });

  // The page number goes with a dropped link size: it counted pages of that
  // size, so it would point at different items.
  const dropLinkedPerPage = () => {
    const { perPage: _perPage, page: _page, ...query } = route.query;

    void router.replace({ query });
  };

  watch(
    [linkedPerPage, savedPerPage],
    ([linked, saved]) => {
      if (linked && !isPageSize(linked)) {
        dropLinkedPerPage();
      }

      if (saved !== undefined && !isPageSize(saved)) {
        paginationStore.removeByKey(key.value);
      }
    },
    { immediate: true },
  );

  // The page goes first: at a new size the old page number means different
  // items and can lie past the end, and the size change alone already refetches.
  const updatePerPage = async (newPerPage: string | number) => {
    if (route.query.perPage || route.query.page) {
      const { perPage: _perPage, page: _page, ...query } = route.query;

      await router.replace({ query });
    }

    paginationStore.setBykey(key.value, newPerPage);
  };

  const page = computed(() => (route.query.page as string) || "1");

  const queryClient = useQueryClient();

  watch(
    () => page.value,
    () => {
      void queryClient.invalidateQueries({
        queryKey: [queryKey],
      });
    },
  );

  watch(
    () => perPage.value,
    () => {
      void queryClient.invalidateQueries({
        queryKey: [queryKey],
      });
    },
  );

  // A shared size can still be above what this list allows, which the API
  // refuses with a 400. Dropping the size that caused it changes the request,
  // and the list refetches at its default.
  const listKey = () => {
    const value = unref(queryKey);

    return Array.isArray(value) ? value[0] : value;
  };

  const unsubscribe = queryClient.getQueryCache().subscribe((event) => {
    if (event.type !== "updated" || event.action.type !== "error") {
      return;
    }

    if (event.query.queryKey[0] !== listKey()) {
      return;
    }

    if (
      errorCodeFrom(event.action.error) !== "pagination.max_per_page_reached"
    ) {
      return;
    }

    if (linkedPerPage.value) {
      dropLinkedPerPage();
    } else if (savedPerPage.value !== undefined) {
      paginationStore.removeByKey(key.value);
    }
  });

  onScopeDispose(unsubscribe);

  return {
    perPage,
    page,
    updatePerPage,
  };
};
