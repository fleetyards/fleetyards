<script lang="ts">
export default {
  name: "EquipmentList",
};
</script>

<script lang="ts" setup>
import EquipmentRow from "@/frontend/components/Equipment/Row/index.vue";
import RowList from "@/shared/components/RowList/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type Equipment } from "@/services/fyApi";

type Props = {
  equipment: Equipment[];
  emptyVisible?: boolean;
};

defineProps<Props>();

const { t } = useI18n();
</script>

<template>
  <RowList
    :records="equipment"
    :empty-visible="emptyVisible"
    :empty-name="t('labels.filters.equipment.name')"
  >
    <template #default="{ record }">
      <EquipmentRow :equipment="record" />
    </template>
  </RowList>
</template>
