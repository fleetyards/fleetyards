<template>
  <div
    ref="modal"
    :class="{
      in: isOpen,
      show: isShow,
      wide: wide,
    }"
    class="modal fade"
    @click.self="close"
  >
    <div class="modal-dialog">
      <Panel :outer-spacing="false">
        <div class="modal-content">
          <div class="modal-header">
            <a v-if="closable" class="close" aria-label="Close" @click="close">
              <i class="fal fa-times" />
            </a>
            <h2 class="modal-title">
              {{ title }}
            </h2>
          </div>
          <div class="modal-body">
            <slot />
          </div>
        </div>
      </Panel>
      <div v-if="$slots['footer']" class="modal-footer">
        <slot name="footer" />
        <div class="clearfix" />
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop, Ref } from 'vue-property-decorator'
import { Action } from 'vuex-class'
import Panel from 'frontend/components/Panel/index.vue'

@Component({
  components: {
    Panel,
  },
})
export default class Modal extends Vue {
  @Action('showOverlay', { namespace: 'app' }) showOverlay: any

  @Action('hideOverlay', { namespace: 'app' }) hideOverlay: any

  @Ref('modal') readonly modal!: HTMLElement

  isShow: boolean = false

  isOpen: boolean = false

  @Prop({ required: true })
  private title!: string

  @Prop({ default: false })
  private visible!: boolean

  @Prop({ default: false })
  private wide!: boolean

  @Prop({ default: true })
  private closable!: boolean

  created() {
    this.isShow = this.visible
    this.isOpen = this.visible
  }

  public open() {
    this.isShow = true
    this.showOverlay()

    this.$nextTick(function onOpen() {
      this.isOpen = true
      this.$refs.modal.focus()
      this.$emit('open')
    })
  }

  public close(force = false) {
    if (!this.closable && !force) {
      return
    }

    this.isOpen = false
    this.hideOverlay()

    this.$nextTick(function onClose() {
      setTimeout(() => {
        this.isShow = false
        this.$emit('close')
      }, 500)
    })
  }
}
</script>

<style lang="scss">
@import 'index';
</style>
