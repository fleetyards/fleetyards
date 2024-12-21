import { debounce } from "ts-debounce";

export const useFilters = <T>({
  allowedKeys,
  ignoreKeys,
  updateCallback,
}: {
  allowedKeys?: (keyof T)[];
  ignoreKeys?: (keyof T)[];
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
        return [...(ignoreKeys || []), ...defaultAllowedKeys].includes(
          key as keyof T,
        );
      })
      .forEach((key) => delete query[key]);

    return Object.keys(query).length > 0;
  });

  const router = useRouter();

  const debouncedFilter = (filter: T) => {
    router
      .replace({
        ...route,
        query: getQuery(filter),
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
