<template>
  <transition name="back-to-top-fade">
    <div
      v-show="visible"
      :title="$t('actions.backToTop')"
      class="back-to-top"
      @click="backToTop"
    >
      <i class="fal fa-chevron-up" />
    </div>
  </transition>
</template>

<script>
export default {
  name: 'BackToTop',

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
      this.visible = window.pageYOffset > parseInt(this.visibleOffset, 10)
    }

    window.onscroll = catchScroll
  },

  methods: {
    backToTop() {
      window.scrollTo({ top: 0, behavior: 'smooth' })
    },
  },
}
</script>
