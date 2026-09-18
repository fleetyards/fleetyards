<script lang="ts">
export default {
  name: "ComponentsList",
};
</script>

<script lang="ts" setup>
import ComponentRow from "@/frontend/components/Components/Row/index.vue";
import RowList from "@/shared/components/RowList/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type Component } from "@/services/fyApi";

type Props = {
  components: Component[];
  emptyVisible?: boolean;
};

defineProps<Props>();

const { t } = useI18n();
</script>

<template>
  <RowList
    :records="components"
    :empty-visible="emptyVisible"
    :empty-name="t('labels.filters.components.name')"
  >
    <template #default="{ record }">
      <ComponentRow :component="record" />
    </template>
  </RowList>
</template>
