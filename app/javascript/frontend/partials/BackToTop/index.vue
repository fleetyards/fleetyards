<template>
  <transition name="back-to-top-fade">
    <div
      v-show="visible"
      :title="$t('actions.backToTop')"
      class="back-to-top"
      :class="cssClasses"
      @click="backToTop"
    >
      <div class="primary-action-inner">
        <i class="fal fa-chevron-up" />
      </div>
    </div>
  </transition>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'

@Component
export default class BackToTop extends Vue {
  visible: boolean = false

  @Prop({ default: 500 }) visibleOffset!: number

  get cssClasses() {
    return {
      'back-to-top-offset': this.$route.meta.primaryAction,
    }
  }

  created() {
    const catchScroll = () => {
      this.visible = window.pageYOffset > this.visibleOffset
    }

    window.onscroll = catchScroll
  }

  backToTop() {
    window.scrollTo(0, 0)
  }
}
</script>
