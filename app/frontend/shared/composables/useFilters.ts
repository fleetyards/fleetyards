import debounce from "lodash.debounce";

export const useFilters = <T>({
  ignoreKeys,
  viewKeys = [],
  updateCallback,
}: {
  ignoreKeys?: string[];
  viewKeys?: string[];
  updateCallback?: (() => void) | (() => Promise<void>);
} = {}) => {
  const route = useRoute();

  const defaultIgnoreKeys = ["s", "sorts"];
  const paginationKeys = ["page", "perPage"];
  // View state that lives in the URL so a reload restores it, and that no
  // endpoint has ever been asked to filter on. `getQuery` spreads the whole
  // route query into `q`, and the query schemas are `additionalProperties:
  // false` -- so a key like this reaches the API as an unknown filter and comes
  // back a 400, which reads as a server error.
  const viewStateKeys = ["tab", "view", "direction", ...viewKeys];

  const excludeKeys = [
    ...defaultIgnoreKeys,
    ...paginationKeys,
    ...viewStateKeys,
  ];

  const filters = computed<T>(() => {
    const query = { ...(route.query || {}) };

    Object.keys(query)
      .filter((key) => excludeKeys.includes(key))
      .forEach((key) => delete query[key]);

    return query as T;
  });

  watch(
    () => filters.value,
    async () => {
      if (!updateCallback) return;

      await updateCallback();
    },
    { deep: true },
  );

  const getQuery = (formData?: T) => {
    const query = {
      ...route.query,
      ...(formData || filters.value),
    };

    Object.keys(query)
      .filter((key) => !query[key] || query[key]?.length === 0)
      .forEach((key) => delete query[key]);

    Object.keys(query)
      .filter((key) => [...paginationKeys, ...viewStateKeys].includes(key))
      .forEach((key) => delete query[key]);

    return query;
  };

  const isFilterSelected = computed(() => {
    const query = getQuery();

    Object.keys(query)
      .filter((key) => {
        return [...(ignoreKeys || []), ...defaultIgnoreKeys].includes(key);
      })
      .forEach((key) => delete query[key]);

    return Object.keys(query).length > 0;
  });

  const router = useRouter();

  /*
   * View state is excluded from `getQuery` because it is not a filter -- but it
   * still belongs in the URL, so every navigation this composable makes has to
   * carry it back. Without this, filtering a list dropped the tab it was on and
   * the page fell back to its default view.
   */
  const viewState = computed(() =>
    Object.fromEntries(
      Object.entries(route.query).filter(([key]) =>
        viewStateKeys.includes(key),
      ),
    ),
  );

  const hasOnlyPageQuery = computed(() => {
    return Object.keys(route.query).length === 1 && route.query.page;
  });

  const shouldResetPage = (query: ReturnType<typeof getQuery>) => {
    return hasOnlyPageQuery.value && Object.keys(query).length > 1;
  };

  const debouncedFilter = (filter: T) => {
    const query = getQuery(filter);

    router
      .replace({
        ...route,
        hash: undefined,
        query: {
          ...query,
          ...viewState.value,
          page: shouldResetPage(query) ? undefined : route.query.page,
        },
      })
      .catch(() => {});
  };

  const resetFilter = () => {
    router
      .replace({
        ...route,
        // Clearing the filters is not leaving the view they were set in.
        query: { ...viewState.value },
      })

      .catch(() => {});
  };

  const hasResettableQuery = computed(() =>
    Object.keys(route.query).some((key) => !viewStateKeys.includes(key)),
  );

  const filter = debounce(debouncedFilter, 300);

  return {
    isFilterSelected,
    hasResettableQuery,
    resetFilter,
    filter,
    filters,
    getQuery,
  };
};
