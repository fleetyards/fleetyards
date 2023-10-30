import { debounce } from "ts-debounce";
import { useRouter, useRoute } from "vue-router/composables";

export type TFilterData = {
  [key: string]:
    | string
    | number
    | boolean
    | string[]
    | number[]
    | boolean[]
    | undefined;
};

const getQuery = (formData: TFilterData) => {
  const query = JSON.parse(JSON.stringify(formData));

  Object.keys(query)
    .filter((key) => !query[key] || query[key].length === 0)
    .forEach((key) => delete query[key]);

  return query;
};

export const useFilters = (routeQueryKey = "q") => {
  const route = useRoute();

  const routeQuery = computed(
    () => (route.query[routeQueryKey] || {}) as TFilterData,
  );

  const isFilterSelected = computed(() => {
    const query = getQuery(routeQuery.value);

    return Object.keys(query).length > 0;
  });

  const router = useRouter();

  const debouncedFilter = (filter: TFilterData) => {
    router
      .replace({
        name: route.name || undefined,
        query: {
          ...route.query,
          [routeQueryKey]: getQuery(filter),
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
  };
};
