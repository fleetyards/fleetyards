<script lang="ts">
export default {
  name: "BaseGrid",
};
</script>

<script lang="ts" setup>
type Props = {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  records: any[];
  primaryKey: string;
  gridBase?: "2" | "3";
  filterVisible?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  gridBase: "3",
  filterVisible: false,
});

const gridClasses = computed(() => {
  if (props.gridBase === "3") {
    return `col-12 col-md-6 col-lg-4 ${gridClassesWithFilter.value}`;
  }

  return `col-12 col-lg-6 col-lgx-3 ${gridClassesWithFilter.value}`;
});

const gridClassesWithFilter = computed(() => {
  if (props.gridBase === "3") {
    if (props.filterVisible) {
      return "col-xxl-3 col-3xl-2dot4";
    }
    return "col-xl-3 col-xxl-2dot4 col-3xl-2";
  }

  if (props.filterVisible) {
    return "col-xxl-3 col-3xl-2dot4";
  }

  return "col-xl-3 col-xxl-2dot4 col-3xl-2";
});

const cssClasses = computed(() => {
  return `fade-list-item ${gridClasses.value}`;
});
</script>

<template>
  <transition-group name="fade-list" class="row" tag="div" :appear="true">
    <div
      v-for="(record, index) in records"
      :key="record[primaryKey]"
      :class="cssClasses"
    >
      <slot :record="record" :index="index" />
    </div>
  </transition-group>
</template>
