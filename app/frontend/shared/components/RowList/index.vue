<script lang="ts">
export default {
  name: "RowList",
};
</script>

<script lang="ts" setup generic="T extends { id: string }">
import Empty from "@/shared/components/Empty/index.vue";

type Props = {
  records: T[];
  emptyVisible?: boolean;
  emptyName?: string;
};

defineProps<Props>();
</script>

<template>
  <div class="row-list">
    <Empty v-if="emptyVisible" :name="emptyName" />

    <div v-else class="row-list__rows">
      <slot v-for="record in records" :key="record.id" :record="record" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
