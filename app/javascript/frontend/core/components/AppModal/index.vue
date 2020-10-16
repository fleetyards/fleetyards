<template>
  <div
    v-if="component"
    ref="modal"
    :class="{
      in: isOpen,
      show: isShow,
      wide: wide,
      fixed: fixed,
    }"
    class="app-modal fade"
    @click.self="close"
  >
    <Component :is="component" v-bind="props" />
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Ref } from 'vue-property-decorator'
import { Action } from 'vuex-class'

type AppModalOptions = {
  component: Promise<VueComponent>
  title: string
  wide: boolean
  fixed: boolean
  props: any
}

@Component<AppModal>({})
export default class AppModal extends Vue {
  @Action('showOverlay', { namespace: 'app' }) showOverlay: any

  @Action('hideOverlay', { namespace: 'app' }) hideOverlay: any

  @Ref('modal') readonly modal!: HTMLElement

  component: string = null

  props: any = null

  wide: boolean = false

  fixed: boolean = false

  isShow: boolean = false

  isOpen: boolean = false

  title: string = null

  mounted() {
    this.$comlink.$on('open-modal', this.open)
    this.$comlink.$on('close-modal', this.close)
  }

  beforeDestroy() {
    this.$comlink.$off('open-modal')
    this.$comlink.$off('close-modal')
  }

  public open(options: AppModalOptions) {
    this.props = options.props
    this.wide = !!options.wide
    this.fixed = !!options.fixed
    this.component = options.component

    this.isShow = true
    this.showOverlay()

    this.$nextTick(() => {
      // make sure the component is present
      setTimeout(() => {
        // make sure initial animations have enough time
        this.isOpen = true
        this.$refs.modal.focus()
        this.$emit('modal-opened')
      }, 50)
    })
  }

  public close(force: boolean = false) {
    if (this.fixed && !force) {
      return
    }

    this.isOpen = false
    this.hideOverlay()

    this.$nextTick(function onClose() {
      setTimeout(() => {
        this.isShow = false
        this.component = null
        this.props = null
        this.$emit('modal-closed')
      }, 300)
    })
  }
}
</script>
