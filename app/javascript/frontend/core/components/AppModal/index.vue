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
    <Component :is="component" ref="modelComponent" v-bind="props" />
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Ref } from 'vue-property-decorator'
import { Action } from 'vuex-class'
import { displayConfirm } from 'frontend/lib/Noty'

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
    this.dirty = !!options.dirty
    this.component = options.component

    this.isShow = true
    this.showOverlay()

    this.$nextTick(() => {
      // make sure the component is present
      setTimeout(() => {
        // make sure initial animations have enough time
        this.isOpen = true

        if (this.$refs.modal) {
          this.$refs.modal.focus()
        }

        this.$emit('modal-opened')
      }, 100)
    })
  }

  public close(force: boolean = false) {
    if (this.fixed && !force) {
      return
    }

    if (this.$refs.modelComponent.dirty) {
      displayConfirm({
        text: this.$t('messages.confirm.modal.dirty'),
        onConfirm: () => {
          this.internalClose()
        },
      })
    } else {
      this.internalClose()
    }
  }

  internalClose() {
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
