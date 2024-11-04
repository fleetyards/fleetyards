<script lang="ts">
export default {
  name: "BaseGrid",
};
</script>

<script lang="ts" setup generic="T">
type Props = {
  records: T[];
  primaryKey: keyof T;
  gridBase?: "2" | "3";
  filterVisible?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  gridBase: "3",
  filterVisible: false,
});

const gridClasses = computed(() => {
  if (props.gridBase === "3") {
    return `columns-1 md:columns-2 lg:columns-4 col-12 col-md-6 col-lg-4 ${gridClassesWithFilter.value}`;
  }

  return `columns-1 lg:columns-2 col-12 col-lg-6 col-lgx-3 ${gridClassesWithFilter.value}`;
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

const primaryValue = (record: T) => {
  return record[props.primaryKey] as string | number;
};
</script>

<template>
  <transition-group name="fade-list" class="row" tag="div" :appear="true">
    <div
      v-for="(record, index) in records"
      :key="primaryValue(record)"
      :class="cssClasses"
    >
      <slot :record="record" :index="index" />
    </div>
  </transition-group>
</template>
