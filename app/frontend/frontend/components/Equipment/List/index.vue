<script lang="ts">
export default {
  name: "EquipmentList",
};
</script>

<script lang="ts" setup>
import EquipmentRow from "@/frontend/components/Equipment/Row/index.vue";
import EquipmentCard from "@/frontend/components/Equipment/Card/index.vue";
import RowList from "@/shared/components/RowList/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type Equipment } from "@/services/fyApi";

type Props = {
  equipment: Equipment[];
  emptyVisible?: boolean;
  gridView?: boolean;
  detailsVisible?: boolean;
  filterVisible?: boolean;
};

defineProps<Props>();

const { t } = useI18n();
</script>

<template>
  <template v-if="gridView">
    <Empty v-if="emptyVisible" :name="t('labels.filters.equipment.name')" />
    <Grid
      v-else
      :records="equipment"
      primary-key="id"
      grid-base="compact"
      :filter-visible="filterVisible"
    >
      <template #default="{ record }">
        <EquipmentCard :equipment="record" :details="detailsVisible" />
      </template>
    </Grid>
  </template>

  <RowList
    v-else
    :records="equipment"
    :empty-visible="emptyVisible"
    :empty-name="t('labels.filters.equipment.name')"
  >
    <template #default="{ record }">
      <EquipmentRow :equipment="record" />
    </template>
  </RowList>
</template>
