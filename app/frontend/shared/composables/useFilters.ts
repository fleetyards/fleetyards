import debounce from "lodash.debounce";

export const useFilters = <T>({
  allowedKeys,
  ignoreKeys,
  updateCallback,
}: {
  allowedKeys?: (keyof T)[];
  ignoreKeys?: string[];
  updateCallback?: () => void;
} = {}) => {
  const route = useRoute();

  const defaultAllowedKeys = ["page", "perPage", "limit", "s", "sorts"];

  onMounted(() => {
    if (!updateCallback) return;

    updateCallback();
  });

  const filters = computed<T>(() => (route.query || {}) as T);

  watch(
    () => filters.value,
    () => {
      if (!updateCallback) return;

      updateCallback();
    },
    { deep: true },
  );

  const getQuery = (formData: T) => {
    const query = {
      ...route.query,
      ...formData,
    };

    Object.keys(query)
      .filter((key) => !query[key] || query[key]?.length === 0)
      .forEach((key) => delete query[key]);

    Object.keys(query)
      .filter((key) => {
        return ![...(allowedKeys || []), ...defaultAllowedKeys].includes(
          key as keyof T,
        );
      })
      .forEach((key) => delete query[key]);

    return query;
  };

  const isFilterSelected = computed(() => {
    const query = getQuery(filters.value);

    Object.keys(query)
      .filter((key) => {
        return [...(ignoreKeys || []), ...defaultAllowedKeys].includes(key);
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
        query: {
          ...query,
          page: shouldResetPage(query) ? undefined : route.query.page,
        },
      })
      // eslint-disable-next-line @typescript-eslint/no-empty-function
      .catch((_error: Error) => {});
  };

  const resetFilter = () => {
    router
      .replace({
        ...route,
        query: {},
      })
      // eslint-disable-next-line @typescript-eslint/no-empty-function
      .catch((_error: Error) => {});
  };

  const filter = debounce(debouncedFilter, 500);

  return {
    isFilterSelected,
    resetFilter,
    filter,
    filters,
  };
};
