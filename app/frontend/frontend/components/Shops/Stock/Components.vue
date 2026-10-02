<script lang="ts">
export default {
  name: "ShopStockComponents",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import ComponentsList from "@/frontend/components/Components/List/index.vue";
import { usePagination } from "@/shared/composables/usePagination";
import { useComponents, getComponentsQueryKey } from "@/services/fyApi";

type Props = {
  shop: string;
};

const props = defineProps<Props>();

const params = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: { soldAtShop: props.shop },
}));

const { perPage, page, updatePerPage } = usePagination(
  computed(() => getComponentsQueryKey(params)),
);

const { data: components, ...asyncStatus } = useComponents(params);
</script>

<!-- The catalogue's own component list, narrowed to the shop. -->
<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <ComponentsList :components="components?.items ?? []" />
      <Paginator
        :query-result-ref="components"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </AsyncData>
</template>
