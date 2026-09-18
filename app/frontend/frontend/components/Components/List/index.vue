<script lang="ts">
export default {
  name: "ComponentsList",
};
</script>

<script lang="ts" setup>
import ComponentRow from "@/frontend/components/Components/Row/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type Component } from "@/services/fyApi";

type Props = {
  components: Component[];
  emptyVisible?: boolean;
};

withDefaults(defineProps<Props>(), { emptyVisible: false });

const { t } = useI18n();

// Rows rather than a table: not one component carries a picture, so a grid of
// tiles would be a grid of placeholders -- and a row carries the figure that
// means something for its own kind, which a fixed column cannot. A gun leads
// with sustained DPS and a cooler with cooling rate, in the same list.
//
// The sort line is not here. It belongs beside this rather than inside it: a
// list renders only once its first page has arrived, and a control that is
// missing while the thing it controls is loading is the wrong way round. See
// `useComponentSortFields`.
</script>

<template>
  <div class="components-list">
    <Empty v-if="emptyVisible" :name="t('labels.filters.components.name')" />

    <div v-else class="components-list__rows">
      <ComponentRow
        v-for="record in components"
        :key="record.id"
        :component="record"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
