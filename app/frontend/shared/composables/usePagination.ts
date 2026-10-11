import {
  isNavigationFailure,
  NavigationFailureType,
  useRoute,
  useRouter,
  type LocationQueryValue,
} from "vue-router";
import { usePaginationStore } from "@/shared/stores/pagination";

// The sizes any list can offer, as `PageSizes::STEPS` in the API declares them,
// plus "all", which the API answers wherever it is asked. A size off this set,
// saved or linked from before, fills no grid row evenly.
const PAGE_SIZES = ["12", "24", "48", "96", "144", "240", "all"];

const isPageSize = (size: string | number | null | undefined) =>
  size !== undefined && size !== null && PAGE_SIZES.includes(String(size));

const firstOf = (
  value: LocationQueryValue | LocationQueryValue[] | undefined,
): LocationQueryValue | undefined => (Array.isArray(value) ? value[0] : value);

export const usePagination = () => {
  const paginationStore = usePaginationStore();

  const route = useRoute();

  const router = useRouter();

  // The route this list belongs to. A page transition keeps the leaving page
  // mounted for a moment while the route already names the next one, so the
  // list holds its size and page, and leaves the next page's alone.
  const listRoute = route.name;

  const key = (listRoute as string) || "";

  const onListRoute = () => route.name === listRoute;

  const linkedPerPage = computed(() => firstOf(route.query.perPage));

  const savedPerPage = computed(() => paginationStore.findByKey(key));

  // A shared link carries the sender's page size, so it shows the same items
  // without overwriting the size this visitor keeps for the list. A size off
  // the shared set is never requested.
  const perPage = computed<string | undefined>((previous) => {
    if (!onListRoute()) {
      return previous;
    }

    if (isPageSize(linkedPerPage.value)) {
      return String(linkedPerPage.value);
    }

    if (isPageSize(savedPerPage.value)) {
      return String(savedPerPage.value);
    }

    return undefined;
  });

  const page = computed<string>((previous) => {
    if (!onListRoute()) {
      return previous ?? "1";
    }

    return (firstOf(route.query.page) as string) || "1";
  });

  // The page number goes with a dropped size: it counted pages of that size.
  watch(
    [linkedPerPage, savedPerPage],
    ([linked, saved]) => {
      if (!onListRoute()) {
        return;
      }

      if (linked && !isPageSize(linked)) {
        const { perPage: _perPage, page: _page, ...query } = route.query;

        void router.replace({ query });
      }

      if (saved !== undefined && !isPageSize(saved)) {
        paginationStore.removeByKey(key);
      }
    },
    { immediate: true },
  );

  // The size and page one land in one navigation, so no request goes out at
  // one without the other, and nothing is saved if that navigation fails.
  const updatePerPage = async (newPerPage: string | number) => {
    if (!isPageSize(newPerPage)) {
      return;
    }

    const { page: _page, ...query } = route.query;

    const failure = await router.replace({
      query: { ...query, perPage: String(newPerPage) },
    });

    if (
      failure &&
      !isNavigationFailure(failure, NavigationFailureType.duplicated)
    ) {
      return;
    }

    paginationStore.setBykey(key, newPerPage);
  };

  return {
    perPage,
    page,
    updatePerPage,
  };
};
