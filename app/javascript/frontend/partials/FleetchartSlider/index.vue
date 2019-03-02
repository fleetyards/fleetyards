<template>
  <vue-slider
    ref="scaleSlider"
    v-model="scale"
    :min="10"
    :max="500"
    :interval="10"
    dot-size="20"
    :marks="mark"
    :tooltip-formatter="'{value} %'"
    lazy
  />
</template>

<script>
import VueSlider from 'vue-slider-component'
import 'vue-slider-component/theme/default.css'

export default {
  components: {
    VueSlider,
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
      mark(value) {
        if (value % 100 === 0 || value === 10) {
          return {
            label: false,
          }
        }
        return false
      },
    }
  },
  watch: {
    scale(value) {
      this.$store.commit(`set${this.scaleKey}`, value)
    },
  },
}
</script>

<style lang="scss">
  @import "./styles/index";
</style>
