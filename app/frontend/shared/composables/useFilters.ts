import { debounce } from "ts-debounce";

export const useFilters = <T>(
  updateCallback?: () => void,
  routeQueryKey = "q",
) => {
  const route = useRoute();

  onMounted(() => {
    if (!updateCallback) return;

    updateCallback();
  });

  watch(
    () => route.query,
    () => {
      if (!updateCallback) return;

      updateCallback();
    },
    { deep: true },
  );

  const getQuery = (formData: T) => {
    const query = JSON.parse(JSON.stringify(formData));

    Object.keys(query)
      .filter((key) => !query[key] || query[key].length === 0)
      .forEach((key) => delete query[key]);

    return query;
  };

  const routeQuery = computed(() => (route.query[routeQueryKey] || {}) as T);

  const isFilterSelected = computed(() => {
    const query = getQuery(routeQuery.value);

    return Object.keys(query).length > 0;
  });

  const router = useRouter();

  const debouncedFilter = (filter: Event) => {
    router
      .replace({
        name: route.name || undefined,
        query: {
          ...route.query,
          [routeQueryKey]: getQuery(filter as T),
        },
      })
      // eslint-disable-next-line @typescript-eslint/no-empty-function
      .catch((_error: Error) => {});
  };

  const resetFilter = () => {
    router
      .replace({
        name: route.name || undefined,
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
    routeQuery,
  };
};
