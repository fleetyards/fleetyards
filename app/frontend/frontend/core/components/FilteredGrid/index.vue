<template>
  <transition-group name="fade-list" class="row" tag="div" :appear="true">
    <div
      v-for="(record, index) in records"
      :key="record[primaryKey]"
      :class="{
        'col-xxl-3 col-3xl-2dot4': filterVisible,
        'col-xl-3 col-xxl-2dot4 col-3xl-2': !filterVisible,
      }"
      class="col-12 col-sm-6 col-lg-4 fade-list-item"
    >
      <slot :record="record" :index="index" />
    </div>
  </transition-group>
</template>

<script>
export default {
  name: 'FilteredGrid',

  props: {
    filterVisible: {
      required: true,
      type: Boolean,
    },

    primaryKey: {
      required: true,
      type: String,
    },

    records: {
      required: true,
      type: Array,
    },
  },
}
</script>
