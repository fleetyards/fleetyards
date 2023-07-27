import { useRoute } from "vue-router";
import { BaseList } from "@/services/fyApi";
import { usePaginationStore } from "@/shared/stores/pagination";

export const usePagination = (
  key: string,
  queryResultRef: Ref<BaseList>,
  changeCallback: () => void
) => {
  const paginationStore = usePaginationStore();

  const perPage = computed(() => String(paginationStore.findByKey(key)));

  const updatePerPage = (newPerPage: string | number) => {
    paginationStore.setBykey(key, newPerPage);
  };

  const route = useRoute();

  const page = computed(() => (route.query.page as string) || "1");

  const pagination = computed(() => queryResultRef.value?.meta?.pagination);

  watch(
    () => page.value,
    () => {
      changeCallback();
    }
  );

  watch(
    () => perPage.value,
    () => {
      changeCallback();
    }
  );

  return {
    perPage,
    page,
    pagination,
    updatePerPage,
  };
};
