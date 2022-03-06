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

<script>
import { mapGetters } from 'vuex'
import VueSlider from 'vue-slider-component'

export default {
  name: 'FleetchartSlider',

  components: {
    VueSlider,
  },

  props: {
    interval: {
      type: Number,
      default: 0.5,
    },

    mark: {
      type: Number,
      default: 2,
    },

    maxScale: {
      type: Number,
      default: 20,
    },

    minScale: {
      type: Number,
      default: 0.2,
    },

    value: {
      type: Number,
      required: true,
    },
  },

  data() {
    return {
      innerValue: 1,
    }
  },

  computed: {
    ...mapGetters(['mobile']),

    innerMark() {
      return this.mobile ? 5 : this.mark
    },
  },

  watch: {
    value() {
      this.innerValue = this.value
    },
  },

  mounted() {
    this.innerValue = this.value
  },

  methods: {
    label(value) {
      return `${value}x`
    },

    marks(value) {
      if (value % this.innerMark === 0) {
        return {
          label: this.label(value),
        }
      }

      return false
    },

    update(value) {
      this.$emit('input', value)
    },
  },
}
</script>
