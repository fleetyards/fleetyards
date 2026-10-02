<script lang="ts">
export default {
  name: "ShopStockEquipment",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import EquipmentList from "@/frontend/components/Equipment/List/index.vue";
import { usePagination } from "@/shared/composables/usePagination";
import { useEquipment, getEquipmentQueryKey } from "@/services/fyApi";

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
  computed(() => getEquipmentQueryKey(params)),
);

const { data: equipment, ...asyncStatus } = useEquipment(params);
</script>

<!-- The catalogue's own equipment list, narrowed to the shop. -->
<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <EquipmentList :equipment="equipment?.items ?? []" />
      <Paginator
        :query-result-ref="equipment"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </AsyncData>
</template>
