<template>
  <div
    v-if="station"
    v-tooltip="tooltip"
  >
    <template v-if="station.type === 'rest_stop'">
      {{ suffix }}
    </template>
    <template v-else-if="suffix">
      {{ prefix }} <router-link
        :to="{
          name: 'celestial-object',
          params: {
            starsystem: location.starsystem.slug,
            slug: location.slug,
          }
        }"
      >
        {{ location.name }}
      </router-link>, {{ suffix }}
    </template>
    <template v-else>
      {{ prefix }} <router-link
        :to="{
          name: 'celestial-object',
          params: {
            starsystem: location.starsystem.slug,
            slug: location.slug,
          }
        }"
      >
        {{ location.name }}
      </router-link>
    </template>
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

  computed: {
    location() {
      return this.station.celestialObject
    },

    label() {
      if (this.suffix) {
        if (this.location) {
          return `${this.prefix} ${this.location.name}, ${this.suffix}`
        }

        return this.suffix
      }

      return `${this.prefix} ${this.location.name}`
    },

    tooltip() {
      if (this.label.length > 50) {
        return this.label
      }

      return null
    },

    prefix() {
      switch (this.station.type) {
        case 'asteroid-station':
          return this.$t('labels.station.locationPrefix.asteriod')
        case 'hub':
        case 'station':
        case 'cargo-station':
        case 'mining-station':
          return this.$t('labels.station.locationPrefix.orbit')
        default:
          return this.$t('labels.station.locationPrefix.default')
      }
    },

    suffix() {
      if (this.station.location) {
        return this.$t('labels.station.locationSuffix', { location: this.station.location })
      }

      return null
    },
  },
}
</script>
