import { useRoute } from "vue-router";
import { usePaginationStore } from "@/shared/stores/pagination";
import { useQueryClient } from "@tanstack/vue-query";

export const usePagination = (key: string) => {
  const paginationStore = usePaginationStore();

  const perPage = computed(() => {
    if (!paginationStore.findByKey(key)) {
      return undefined;
    }

    return paginationStore.findByKey(key) as string;
  });

  const updatePerPage = (newPerPage: string | number) => {
    paginationStore.setBykey(key, newPerPage);
  };

  const route = useRoute();

  const page = computed(() => (route.query.page as string) || "1");

  const queryClient = useQueryClient();

  watch(
    () => page.value,
    () => {
      queryClient.invalidateQueries({
        queryKey: [key],
      });
    },
  );

  watch(
    () => perPage.value,
    () => {
      queryClient.invalidateQueries({
        queryKey: [key],
      });
    },
  );

  return {
    perPage,
    page,
    updatePerPage,
  };
};
