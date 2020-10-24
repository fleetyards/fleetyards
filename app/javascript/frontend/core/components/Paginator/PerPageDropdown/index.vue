<template>
  <BtnDropdown size="small">
    <template #label>{{ $t('labels.perPage') }}: {{ perPage }}</template>
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
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import BtnDropdown from 'frontend/core/components/BtnDropdown'
import Btn from 'frontend/core/components/Btn'

@Component<PerPageDropdown>({
  components: {
    BtnDropdown,
    Btn,
  },
})
export default class PerPageDropdown extends Vue {
  @Prop({ required: true }) perPage!: number

  @Prop({
    default: () => {
      return [10, 20, 50, 100]
    },
  })
  steps!: number[]

  get uuid() {
    return this._uid
  }

  update(step) {
    this.$emit('change', step)
  }
}
</script>
