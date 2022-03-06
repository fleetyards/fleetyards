<template>
  <div
    ref="panelDetails"
    class="panel-details"
    :style="{ height: `${height}px` }"
  >
    <slot />
  </div>
</template>

<script>
export default {
  name: 'PanelDetails',

  props: {
    visible: {
      type: Boolean,
      default: false,
    },
  },

  data() {
    return {
      height: 0,
    }
  },

  watch: {
    visible() {
      this.setupHeight()
    },
  },

  mounted() {
    this.setupHeight()
  },

  methods: {
    setupHeight() {
      if (this.visible) {
        this.height = this.$refs.panelDetails.scrollHeight
      } else {
        this.height = 0
      }
    },
  },
}
</script>
