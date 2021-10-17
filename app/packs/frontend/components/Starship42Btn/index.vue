<template>
  <Btn
    v-if="vehicles && vehicles.length"
    v-tooltip="tooltip"
    :variant="variant"
    :size="size"
    :inline="inline"
    @click.native="openStarship42"
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

  get basePath() {
    return 'https://starship42.com/fleetview/'
  }

  get tooltip() {
    if (this.mobile) {
      return null
    }

    // @ts-ignore
    return this.$t('labels.poweredByStarship42')
  }

  openStarship42() {
    const form = document.createElement('form')
    form.method = 'post'
    form.action = this.basePath

    this.vehicles.forEach(vehicle => {
      const hiddenField = document.createElement('input')
      hiddenField.type = 'hidden'
      hiddenField.name = 's[]'
      hiddenField.value = vehicle.model.rsiName

      form.appendChild(hiddenField)
    })

    document.body.appendChild(form)
    form.submit()
  }
}
</script>
