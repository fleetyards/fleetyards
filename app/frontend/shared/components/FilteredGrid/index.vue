<template>
  <transition-group name="fade-list" class="row" tag="div" :appear="true">
    <div
      v-for="(record, index) in records"
      :key="record[primaryKey] as string"
      :class="{
        'col-xxl-3 col-3xl-2dot4': filterVisible,
        'col-xl-3 col-xxl-2dot4 col-3xl-2': !filterVisible,
      }"
      class="col-12 col-md-6 col-lg-4 fade-list-item"
    >
      <slot :record="record" :index="index" />
    </div>
  </transition-group>
</template>

<script lang="ts" setup>
type Props = {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  records: any[];
  primaryKey: string;
  filterVisible: boolean;
};

defineProps<Props>();
</script>

<script lang="ts">
export default {
  name: "FilteredGrid",
};
</script>
