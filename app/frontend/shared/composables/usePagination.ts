import { useRoute, useRouter, type LocationQueryValue } from "vue-router";
import { usePaginationStore } from "@/shared/stores/pagination";
import { useQuery } from "@tanstack/vue-query";
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

type PaginatedData = { meta?: { pagination?: { perPageSteps?: unknown[] } } };

export const usePagination = (
  queryKey?: MaybeRef<QueryKey | string | undefined>,
) => {
  const paginationStore = usePaginationStore();

  const route = useRoute();

  const router = useRouter();

  // The route this list belongs to. A page transition keeps the leaving page
  // mounted for a moment while the route already names the next one, whose
  // saved and linked sizes are none of this list's business.
  const listRoute = route.name;

  const key = (listRoute as string) || "";

  const onListRoute = () => route.name === listRoute;

  // This list's own query, observed and never fetched: its answer names the
  // sizes the list offers, and its error says when a size was refused. No
  // placeholder, so a new key never shows the steps of the last one.
  //
  // The caller builds its key from the `perPage` and `page` this returns, so
  // reading it during setup would touch them before they exist: the key is
  // read from mount on.
  const mounted = ref(!getCurrentInstance());

  onMounted(() => {
    mounted.value = true;
  });

  const ownQuery = useQuery({
    queryKey: computed(() => {
      if (!mounted.value) {
        return ["usePagination", "unmounted"] as QueryKey;
      }

      const value = unref(queryKey);

      return (Array.isArray(value) ? value : [value]) as QueryKey;
    }),
    enabled: false,
    placeholderData: undefined,
  });

  const listSteps = computed(() =>
    (
      ownQuery.data.value as PaginatedData | undefined
    )?.meta?.pagination?.perPageSteps?.map(String),
  );

  const offered = (size: string | number | null | undefined) =>
    isPageSize(size) &&
    (!listSteps.value || listSteps.value.includes(String(size)));

  const linkedPerPage = computed(() => firstOf(route.query.perPage));

  const savedPerPage = computed(() => paginationStore.findByKey(key));

  // Set while a picked size waits for the route to drop the old page, so the
  // new size and page one reach the request together.
  const pending = ref<string>();

  // A shared link carries the sender's page size, so it shows the same items
  // without overwriting the size this visitor keeps for the list. A size off
  // the shared set is never requested; one this list turns out not to offer is
  // dropped once its answer says so.
  const perPage = computed(() => {
    if (pending.value) {
      return pending.value;
    }

    if (isPageSize(linkedPerPage.value)) {
      return String(linkedPerPage.value);
    }

    if (isPageSize(savedPerPage.value)) {
      return String(savedPerPage.value);
    }

    return undefined;
  });

  const page = computed(() =>
    pending.value ? "1" : (route.query.page as string) || "1",
  );

  // The page number goes with the size: it counted pages of that size, so it
  // would point at different items, and can lie past the end.
  const clearSizeFromQuery = () => {
    const { perPage: _perPage, page: _page, ...query } = route.query;

    return router.replace({ query });
  };

  watch(
    [linkedPerPage, savedPerPage, listSteps],
    ([linked, saved]) => {
      if (!onListRoute()) {
        return;
      }

      if (linked && !offered(linked)) {
        void clearSizeFromQuery();
      }

      if (saved !== undefined && !offered(saved)) {
        paginationStore.removeByKey(key);
      }
    },
    { immediate: true },
  );

  // A size above what this list allows is refused with a 400 before the list
  // has named its sizes. The refused request is this list's own, so it asked
  // for the size in use: dropping that one refetches at the default.
  watch(
    () => ownQuery.error.value,
    (error) => {
      if (
        !onListRoute() ||
        errorCodeFrom(error) !== "pagination.max_per_page_reached"
      ) {
        return;
      }

      if (isPageSize(linkedPerPage.value)) {
        void clearSizeFromQuery();
      } else if (savedPerPage.value !== undefined) {
        paginationStore.removeByKey(key);
      }
    },
  );

  const updatePerPage = async (newPerPage: string | number) => {
    if (!offered(newPerPage)) {
      return;
    }

    pending.value = String(newPerPage);

    try {
      if (route.query.perPage || route.query.page) {
        await clearSizeFromQuery();
      }

      paginationStore.setBykey(key, newPerPage);
    } finally {
      pending.value = undefined;
    }
  };

  return {
    perPage,
    page,
    updatePerPage,
  };
};
