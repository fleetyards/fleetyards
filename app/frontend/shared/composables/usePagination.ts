import { useRoute, useRouter } from "vue-router";
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

  const router = useRouter();

  // A shared link carries the sender's page size, so it shows the same items
  // without overwriting the size this visitor keeps for the list.
  const perPage = computed(() => {
    if (route.query.perPage) {
      return String(route.query.perPage);
    }

    if (!paginationStore.findByKey(key.value)) {
      return undefined;
    }

    return paginationStore.findByKey(key.value) as string;
  });

  const updatePerPage = (newPerPage: string | number) => {
    paginationStore.setBykey(key.value, newPerPage);

    if (route.query.perPage) {
      const { perPage: _perPage, ...query } = route.query;

      void router.replace({ query });
    }
  };

  const page = computed(() => (route.query.page as string) || "1");

  const queryClient = useQueryClient();

  watch(
    () => page.value,
    () => {
      void queryClient.invalidateQueries({
        queryKey: [queryKey],
      });
    },
  );

  watch(
    () => perPage.value,
    () => {
      void queryClient.invalidateQueries({
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
