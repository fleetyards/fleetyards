<template>
  <div>
    <div class="metrics-label">{{ docks.length }}x {{ size }}:</div>
    <div class="metrics-value">
      {{ sortedDocks.map(dock => dock.name).join(', ') }}
    </div>
  </div>
</template>

<script>
import { sortBy } from 'frontend/lib/Helpers'

export default {
  props: {
    docks: {
      type: Array,
      required: true,
    },

    size: {
      type: String,
      required: true,
    },
  },

  computed: {
    sortedDocks() {
      return sortBy(this.docks, 'name')
    },
  },
}
</script>

<style lang="scss" scoped>
.dock-item {
  display: inline-block;
  padding-right: 5px;
  white-space: nowrap;
}
</style>
