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

  // The page goes first: at a new size the old page number means different
  // items and can lie past the end, and the size change alone already refetches.
  const updatePerPage = async (newPerPage: string | number) => {
    if (route.query.perPage || route.query.page) {
      const { perPage: _perPage, page: _page, ...query } = route.query;

      await router.replace({ query });
    }

    paginationStore.setBykey(key.value, newPerPage);
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
