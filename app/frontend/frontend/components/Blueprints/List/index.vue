<script lang="ts">
export default {
  name: "BlueprintsList",
};
</script>

<script lang="ts" setup>
import BlueprintRow from "@/frontend/components/Blueprints/Row/index.vue";
import RowList from "@/shared/components/RowList/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type Blueprint } from "@/services/fyApi";

type Props = {
  blueprints: Blueprint[];
  emptyVisible?: boolean;
};

defineProps<Props>();

const { t } = useI18n();
</script>

<template>
  <RowList
    :records="blueprints"
    :empty-visible="emptyVisible"
    :empty-name="t('labels.filters.blueprints.name')"
  >
    <template #default="{ record }">
      <BlueprintRow :blueprint="record" />
    </template>
  </RowList>
</template>
