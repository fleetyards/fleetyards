import { useRoute } from "vue-router";
import { usePaginationStore } from "@/shared/stores/pagination";
import { useQueryClient } from "@tanstack/vue-query";
import type { QueryKey } from "@tanstack/vue-query";
import type { MaybeRef } from "vue";

export const usePagination = (
  queryKey: MaybeRef<QueryKey | string | undefined>,
) => {
  const paginationStore = usePaginationStore();

  const route = useRoute();

  const key = computed(() => {
    return (route.name as string) || "";
  });

  const perPage = computed(() => {
    if (!paginationStore.findByKey(key.value)) {
      return undefined;
    }

    return paginationStore.findByKey(key.value) as string;
  });

  const updatePerPage = (newPerPage: string | number) => {
    paginationStore.setBykey(key.value, newPerPage);
  };

  const page = computed(() => (route.query.page as string) || "1");

  const queryClient = useQueryClient();

  watch(
    () => page.value,
    () => {
      queryClient.invalidateQueries({
        queryKey: [queryKey],
      });
    },
  );

  watch(
    () => perPage.value,
    () => {
      queryClient.invalidateQueries({
        queryKey: [queryKey],
      });
    },
  );

  return {
    perPage,
    page,
    updatePerPage,
  };
};
