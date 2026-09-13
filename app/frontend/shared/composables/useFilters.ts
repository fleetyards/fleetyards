import debounce from "lodash.debounce";

export const useFilters = <T>({
  ignoreKeys,
  updateCallback,
}: {
  ignoreKeys?: string[];
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
  const viewStateKeys = ["tab"];

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
          page: shouldResetPage(query) ? undefined : route.query.page,
        },
      })
      .catch(() => {});
  };

  const resetFilter = () => {
    router
      .replace({
        ...route,
        query: {},
      })

      .catch(() => {});
  };

  const filter = debounce(debouncedFilter, 300);

  return {
    isFilterSelected,
    resetFilter,
    filter,
    filters,
    getQuery,
  };
};
