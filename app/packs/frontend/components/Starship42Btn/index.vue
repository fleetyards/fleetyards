<template>
  <Btn
    v-if="vehicles && vehicles.length"
    v-tooltip="tooltip"
    :href="url"
    :variant="variant"
    :size="size"
    :inline="inline"
  >
    <template v-if="withIcon">
      <i class="fad fa-cube" />
      <span>{{ $t('labels.exportStarship42') }}</span>
    </template>
    <span v-else>
      {{ $t('labels.3dView') }}
    </span>
  </Btn>
</template>

<script lang="ts">
import qs from 'qs'
import { Component, Prop } from 'vue-property-decorator'
import Btn from 'frontend/core/components/Btn/index.vue'
import { Getter } from 'vuex-class'

@Component({
  components: {
    Btn,
  },
})
export default class Panel extends Btn {
  @Prop({ required: true }) vehicles!: Vehicle[]

  @Prop({ default: false }) withIcon!: boolean

  @Getter('mobile') mobile

  get url() {
    const shipList = this.vehicles.map(vehicle => {
      if (!vehicle.model) {
        return null
      }

      if (vehicle.paint && vehicle.paint.rsiId) {
        return vehicle.paint.rsiName
      }

      return vehicle.model.rsiName
    })

    const data = { type: 'matrix', s: shipList }

    return `http://www.starship42.com/fleetview/?${qs.stringify(data)}`
  }

  get tooltip() {
    if (this.mobile) {
      return null
    }

    // @ts-ignore
    return this.$t('labels.poweredByStarship42')
  }
}
</script>
