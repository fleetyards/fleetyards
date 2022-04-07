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
    lazy
    @change="updateScale"
  />
</template>

<script>
import VueSlider from 'vue-slider-component'

export default {
  name: 'SliderComponent',

  components: {
    VueSlider,
  },

  props: {
    initialScale: {
      type: Number,
      required: true,
    },
  },

  data() {
    return {
      scale: null,
    }
  },

  computed: {
    max() {
      return this.mobile ? 100 : 300
    },
  },

  mounted() {
    this.scale = this.initialScale
  },

  methods: {
    updateScale(value) {
      this.$emit('change', value)
    },

    mark(value) {
      if (value % 50 === 0 || value === 10) {
        return {
          label: this.label(value),
        }
      }
      return false
    },

    label(value) {
      return `${value} %`
    },
  },
}
</script>
