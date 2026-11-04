<script lang="ts">
export default {
  name: "ComponentsList",
};
</script>

<script lang="ts" setup>
import ComponentRow from "@/frontend/components/Components/Row/index.vue";
import ComponentCard from "@/frontend/components/Components/Card/index.vue";
import RowList from "@/shared/components/RowList/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type Component } from "@/services/fyApi";

type Props = {
  components: Component[];
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
    <Empty v-if="emptyVisible" :name="t('labels.filters.components.name')" />
    <Grid
      v-else
      :records="components"
      primary-key="id"
      grid-base="compact"
      :filter-visible="filterVisible"
    >
      <template #default="{ record }">
        <ComponentCard :component="record" :details="detailsVisible" />
      </template>
    </Grid>
  </template>

  <RowList
    v-else
    :records="components"
    :empty-visible="emptyVisible"
    :empty-name="t('labels.filters.components.name')"
  >
    <template #default="{ record }">
      <ComponentRow :component="record" />
    </template>
  </RowList>
</template>
