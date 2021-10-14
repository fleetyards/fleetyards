<template>
  <VueSlider
    ref="scaleSlider"
    v-model="scale"
    :min="10"
    :max="max"
    :interval="10"
    dot-size="20"
    :marks="mark"
    :tooltip-formatter="label"
    :process="false"
    :lazy="true"
    class="fleetchart-slider"
    @change="updateScale"
  />
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import VueSlider from 'vue-slider-component'

@Component<FleetchartSlider>({
  components: {
    VueSlider,
  },
})
export default class FleetchartSlider extends Vue {
  get max() {
    return this.mobile ? 100 : 300
  }

  @Prop({ required: true }) initialScale: Number

  scale: Number = null

  mounted() {
    this.scale = this.initialScale
  }

  updateScale(value) {
    this.$emit('change', value)
  }

  mark(value) {
    if (value % 50 === 0 || value === 10) {
      return {
        label: this.label(value),
      }
    }
    return false
  }

  label(value) {
    return `${value} %`
  }
}
</script>
