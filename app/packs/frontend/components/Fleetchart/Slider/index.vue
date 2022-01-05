<template>
  <div class="fleetchart-slider">
    <VueSlider
      ref="scaleSlider"
      v-model="innerValue"
      :min="minScale"
      :max="maxScale"
      :interval="interval"
      :marks="marks"
      dot-size="20"
      :tooltip-formatter="label"
      :process="false"
      :lazy="true"
      @change="update"
    />
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop, Watch } from 'vue-property-decorator'
import VueSlider from 'vue-slider-component'
import { Getter } from 'vuex-class'

@Component({
  components: {
    VueSlider,
  },
})
export default class FleetchartSlider extends Vue {
  innerValue: number = 1

  @Prop({ required: true }) value!: number

  @Prop({ default: 20 }) maxScale!: number

  @Prop({ default: 0.2 }) minScale!: number

  @Prop({ default: 0.5 }) interval!: number

  @Prop({ default: 2 }) mark!: number

  @Getter('mobile') mobile

  get innerMark() {
    return this.mobile ? 5 : this.mark
  }

  @Watch('value')
  onValueChange() {
    this.innerValue = this.value
  }

  mounted() {
    this.innerValue = this.value
  }

  update(value) {
    this.$emit('input', value)
  }

  marks(value) {
    if (value % this.innerMark === 0) {
      return {
        label: this.label(value),
      }
    }

    return false
  }

  label(value) {
    return `${value}x`
  }
}
</script>
