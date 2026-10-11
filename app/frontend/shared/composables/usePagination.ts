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

// The endpoint part of a query key, without the params: ['fleets', slug,
// 'vehicles'] for a fleet's ships, so a sibling list under the same fleet is
// not mistaken for this one.
const keyPath = (key: unknown) => {
  const value = unref(key);
  const segments = Array.isArray(value) ? value : [value];

  return JSON.stringify(
    segments
      .map((segment) => unref(segment) as unknown)
      .filter((segment) => typeof segment !== "object" || segment === null),
  );
};

type PaginatedData = { meta?: { pagination?: { perPageSteps?: unknown[] } } };

const stepsOf = (data: unknown) =>
  (data as PaginatedData | undefined)?.meta?.pagination?.perPageSteps?.map(
    String,
  );

export const usePagination = (
  queryKey: MaybeRef<QueryKey | string | undefined>,
) => {
  const paginationStore = usePaginationStore();

  const route = useRoute();

  const key = computed(() => {
    return (route.name as string) || "";
  });

  const router = useRouter();

  const queryClient = useQueryClient();

  const isThisList = (other: unknown) => keyPath(other) === keyPath(queryKey);

  // The sizes this list offers, as its last answer named them. Until one has
  // arrived, only the shared set is known.
  const listSteps = ref<string[] | undefined>(
    queryClient
      .getQueryCache()
      .findAll()
      .filter((query) => isThisList(query.queryKey))
      .map((query) => stepsOf(query.state.data))
      .find((steps) => !!steps),
  );

  const offered = (size: string | number | null | undefined) =>
    isPageSize(size) &&
    (!listSteps.value || listSteps.value.includes(String(size)));

  const linkedPerPage = computed(() => firstOf(route.query.perPage));

  const savedPerPage = computed(() => paginationStore.findByKey(key.value));

  // A shared link carries the sender's page size, so it shows the same items
  // without overwriting the size this visitor keeps for the list. A size the
  // list does not offer is never requested: it falls back to the saved size,
  // then to its default.
  const perPage = computed(() => {
    if (offered(linkedPerPage.value)) {
      return String(linkedPerPage.value);
    }

    if (offered(savedPerPage.value)) {
      return String(savedPerPage.value);
    }

    return undefined;
  });

  // The page number goes with the size: it counted pages of that size, so it
  // would point at different items, and can lie past the end.
  const clearSizeFromQuery = () => {
    const { perPage: _perPage, page: _page, ...query } = route.query;

    return router.replace({ query });
  };

  watch(
    [linkedPerPage, savedPerPage, listSteps],
    ([linked, saved]) => {
      if (linked && !offered(linked)) {
        void clearSizeFromQuery();
      }

      if (saved !== undefined && !offered(saved)) {
        paginationStore.removeByKey(key.value);
      }
    },
    { immediate: true },
  );

  // The page goes first, and the size change alone already refetches.
  const updatePerPage = async (newPerPage: string | number) => {
    if (route.query.perPage || route.query.page) {
      await clearSizeFromQuery();
    }

    paginationStore.setBykey(key.value, newPerPage);
  };

  const page = computed(() => (route.query.page as string) || "1");

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

  // A shared size can be above what this list allows, which the API refuses
  // with a 400 before the list has named its sizes. Dropping the size that was
  // requested changes the request, and the list refetches at its default.
  const unsubscribe = queryClient.getQueryCache().subscribe((event) => {
    if (event.type !== "updated" || !isThisList(event.query.queryKey)) {
      return;
    }

    if (event.action.type === "success") {
      const steps = stepsOf(event.action.data);

      if (steps) {
        listSteps.value = steps;
      }

      return;
    }

    if (
      event.action.type !== "error" ||
      errorCodeFrom(event.action.error) !== "pagination.max_per_page_reached"
    ) {
      return;
    }

    if (offered(linkedPerPage.value)) {
      void clearSizeFromQuery();
    } else if (offered(savedPerPage.value)) {
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
