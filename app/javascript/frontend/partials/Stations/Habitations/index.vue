<template>
  <div
    v-if="station.habitations.length"
    class="row"
  >
    <div class="col-xs-12 col-md-3">
      <div class="metrics-title">
        {{ $t('labels.station.habs') }}
      </div>
    </div>
    <div class="col-xs-12 col-md-9 metrics-block">
      <div class="row">
        <div
          v-for="(hab, index) in station.habitations"
          :key="index"
          class="col-xs-6"
        >
          <div class="metrics-label">
            {{ hab.typeLabel }}:
          </div>
          <div
            v-tooltip="hab.typeLabel"
            class="metrics-value"
          >
            {{ hab.count }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    station: {
      type: Object,
      required: true,
    },
  },
}
</script>
