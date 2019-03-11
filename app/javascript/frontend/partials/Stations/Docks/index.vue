<template>
  <div
    v-if="station.docks.length"
    class="row"
  >
    <div class="col-xs-12 col-md-3">
      <div class="metrics-title">
        {{ t('labels.station.docks') }}
      </div>
    </div>
    <div class="col-xs-12 col-md-9 metrics-block">
      <div class="row">
        <div
          v-for="(dock, index) in station.docks"
          :key="index"
          class="col-xs-6"
        >
          <div class="metrics-label">
            {{ dock.size }} {{ dock.typeLabel }}:
          </div>
          <div
            :key="index"
            v-tooltip="`${dock.size} ${dock.typeLabel}`"
            class="metrics-value"
          >
            {{ dock.count }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import I18n from 'frontend/mixins/I18n'

export default {
  mixins: [I18n],
  props: {
    station: {
      type: Object,
      required: true,
    },
  },
}
</script>
