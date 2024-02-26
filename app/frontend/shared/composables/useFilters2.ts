import { debounce } from "ts-debounce";

export const useFilters = <T>(
  allowedKeys: (keyof T)[],
  ignoreKeys?: (keyof T)[],
  updateCallback?: () => void,
) => {
  const route = useRoute();

  const defaultAllowedKeys = ["page", "perPage", "limit"];

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
    const query = {
      ...route.query,
      ...formData,
    };

    Object.keys(query)
      .filter((key) => !query[key] || query[key]?.length === 0)
      .forEach((key) => delete query[key]);

    Object.keys(query)
      .filter((key) => {
        return ![...allowedKeys, ...defaultAllowedKeys].includes(
          key as keyof T,
        );
      })
      .forEach((key) => delete query[key]);

    return query;
  };

  const routeQuery = computed<T>(() => (route.query || {}) as T);

  const isFilterSelected = computed(() => {
    const query = getQuery(routeQuery.value);

    Object.keys(query)
      .filter((key) => {
        return (ignoreKeys || []).includes(key as keyof T);
      })
      .forEach((key) => delete query[key]);

    return Object.keys(query).length > 0;
  });

  const router = useRouter();

  const debouncedFilter = (filter: T) => {
    router
      .replace({
        name: route.name || undefined,
        query: getQuery(filter),
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
