<template>
  <Btn
    v-if="items && items.length"
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
export default class Starship42Btn extends Btn {
  @Prop({ required: true }) items!: Vehicle[] | Model[]

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
    form.target = '_blank'

    const typeField = document.createElement('input')
    typeField.type = 'hidden'
    typeField.name = 'type'
    typeField.value = 'matrix'
    form.appendChild(typeField)

    this.items.forEach(item => {
      const model = item.model || item
      const shipField = document.createElement('input')
      shipField.type = 'hidden'
      shipField.name = 's[]'
      shipField.value = model.rsiName

      form.appendChild(shipField)
    })

    document.body.appendChild(form)
    form.submit()
  }
}
</script>
