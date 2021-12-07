<template>
  <BtnDropdown :size="size" :variant="variant" :mobile-block="true">
    <template #label>
      <template v-if="!mobile">{{ $t('labels.pagination.perPage') }}:</template>
      {{ perPage }}
    </template>
    <Btn
      v-for="(step, index) in steps"
      :key="`per-page-drowndown-${uuid}-${index}-${step}`"
      size="small"
      variant="link"
      @click.native="update(step)"
    >
      {{ step }}
    </Btn>
  </BtnDropdown>
</template>

<script lang="ts">
import { Component, Prop } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import BtnDropdown from 'frontend/core/components/BtnDropdown'
import Btn from 'frontend/core/components/Btn'

@Component<PerPageDropdown>({
  components: {
    BtnDropdown,
    Btn,
  },
})
export default class PerPageDropdown extends BtnDropdown {
  @Prop({ required: true }) perPage!: number

  @Prop({
    default: () => [10, 20, 50, 100],
  })
  steps!: number[]

  @Getter('mobile') mobile

  get uuid() {
    return this._uid
  }

  update(step) {
    this.$emit('change', step)
  }
}
</script>
