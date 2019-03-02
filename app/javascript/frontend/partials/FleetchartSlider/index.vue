<template>
  <vue-slider
    ref="scaleSlider"
    v-model="scale"
    :min="0.1"
    :max="5"
    :interval="0.1"
    tooltip="hover"
  >
    <template v-slot:tooltip="{ value }">
      <div class="slider-tooltip">
        {{ parseInt(value * 100, 10) }} %
      </div>
    </template>
  </vue-slider>
</template>

<script>
import vueSlider from 'vue-slider-component'

export default {
  components: {
    vueSlider,
  },
  props: {
    scaleKey: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      scale: this.$store.getters[this.scaleKey],
    }
  },
  watch: {
    scale(value) {
      this.$store.commit(`set${this.scaleKey}`, value)
    },
  },
  methids: {
    refresh() {
      setTimeout(this.$refs.scaleSlider.refresh, 500)
    },
  },
}
</script>

<style lang="scss" scoped>
  @import "./styles/index";
</style>
