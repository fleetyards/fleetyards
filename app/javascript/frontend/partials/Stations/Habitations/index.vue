<template>
  <div
    v-if="station.habitationCounts.length"
    class="row"
    :class="{
      'metrics-padding': padding,
    }"
  >
    <div class="col-xs-12 col-md-3">
      <div class="metrics-title">
        {{ $t('labels.station.habs') }}
      </div>
    </div>
    <div class="col-xs-12 col-md-9 metrics-block">
      <div class="row">
        <div
          v-for="(habs, name) in habitationsByName"
          :key="name"
          class="col-xs-6"
        >
          <div class="metrics-label">{{ name }}:</div>
          <div class="metrics-value">
            {{ habs.length }}x {{ habs[0].typeLabel }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { groupBy } from 'frontend/lib/Helpers'

export default {
  props: {
    station: {
      type: Object,
      required: true,
    },

    padding: {
      type: Boolean,
      default: false,
    },
  },

  computed: {
    habitationsByName() {
      return groupBy(this.station.habitations, 'habitationName')
    },
  },
}
</script>
