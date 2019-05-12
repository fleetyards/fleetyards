<template>
  <transition name="back-to-top-fade">
    <div
      v-show="visible"
      :title="t('actions.backToTop')"
      class="back-to-top"
      @click="backToTop"
    >
      <i class="fal fa-chevron-up" />
    </div>
  </transition>
</template>

<script>
import I18n from 'frontend/mixins/I18n'

export default {
  name: 'BackToTop',
  mixins: [I18n],
  props: {
    visibleOffset: {
      type: [String, Number],
      default: 600,
    },
  },
  data() {
    return {
      visible: false,
    }
  },
  created() {
    const catchScroll = () => {
      this.visible = (window.pageYOffset > parseInt(this.visibleOffset, 10))
    }
    window.onscroll = catchScroll
  },
  methods: {
    backToTop() {
      this.$scrollTo('#app')
    },
  },
}
</script>

<style lang="scss" scoped>
  @import './styles/index';
</style>
