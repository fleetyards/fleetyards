<script lang="ts">
export default {
  name: "CommoditiesList",
};
</script>

<script lang="ts" setup>
import CommodityRow from "@/frontend/components/Commodities/Row/index.vue";
import RowList from "@/shared/components/RowList/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type Commodity } from "@/services/fyApi";

type Props = {
  commodities: Commodity[];
  emptyVisible?: boolean;
};

defineProps<Props>();

const { t } = useI18n();
</script>

<template>
  <RowList
    :records="commodities"
    :empty-visible="emptyVisible"
    :empty-name="t('labels.filters.commodities.name')"
  >
    <template #default="{ record }">
      <CommodityRow :commodity="record" />
    </template>
  </RowList>
</template>
