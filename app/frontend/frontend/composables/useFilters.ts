import { debounce } from "ts-debounce";
import { useRouter, useRoute } from "vue-router/composables";

type FormData = {
  [key: string]:
    | string
    | number
    | boolean
    | string[]
    | number[]
    | boolean[]
    | undefined;
};

const getQuery = (formData: FormData) => {
  const q = JSON.parse(JSON.stringify(formData));

  Object.keys(q)
    .filter((key) => !q[key] || q[key].length === 0)
    .forEach((key) => delete q[key]);

  return q;
};

export const useFilters = (formData?: FormData) => {
  const form = ref<FormData | undefined>(formData);

  const route = useRoute();

  const isFilterSelected = computed(() => {
    const query = JSON.parse(JSON.stringify(route.query.q || {}));

    Object.keys(query)
      .filter((key) => !query[key] || query[key].length === 0)
      .forEach((key) => delete query[key]);

    return Object.keys(query).length > 0;
  });

  const router = useRouter();

  const debouncedFilter = () => {
    if (!form.value) {
      return;
    }

    router
      .replace({
        name: route.name || undefined,
        query: {
          ...route.query,
          q: getQuery(form.value),
        },
      })
      // eslint-disable-next-line @typescript-eslint/no-empty-function
      .catch((_err) => {});
  };

  const resetFilter = () => {
    router
      .replace({
        name: route.name || undefined,
        query: {},
      })
      // eslint-disable-next-line @typescript-eslint/no-empty-function
      .catch((_err) => {});
  };

  const updateFilter = (updatedFormData: FormData) => {
    form.value = updatedFormData;
  };

  const filter = debounce(debouncedFilter, 500);

  watch(
    () => form.value,
    () => {
      filter();
    },
    { deep: true }
  );

  return {
    form,
    isFilterSelected,
    resetFilter,
    updateFilter,
    filter,
  };
};
