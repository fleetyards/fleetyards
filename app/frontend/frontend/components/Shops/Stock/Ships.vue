<script lang="ts">
export default {
  name: "ShopStockShips",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import ModelPanel from "@/frontend/components/Models/Panel/index.vue";
import { usePagination } from "@/shared/composables/usePagination";
import { useModels, getModelsQueryKey } from "@/services/fyApi";

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
  computed(() => getModelsQueryKey(params)),
);

const { data: models, ...asyncStatus } = useModels(params);
</script>

<!-- The catalogue's own ship cards, narrowed to the shop. -->
<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <Grid :records="models?.items ?? []" primary-key="slug">
        <template #default="{ record }">
          <ModelPanel :model="record" />
        </template>
      </Grid>
      <Paginator
        :query-result-ref="models"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </AsyncData>
</template>
