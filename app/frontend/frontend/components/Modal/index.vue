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

<script>
import { mapActions } from 'vuex'
import Panel from '@/frontend/core/components/Panel/index.vue'

export default {
  name: 'ModalComponent',

  components: {
    Panel,
  },

  props: {
    closable: {
      type: Boolean,
      default: true,
    },

    title: {
      type: String,
      required: true,
    },

    visible: {
      type: Boolean,
      default: false,
    },

    wide: {
      type: Boolean,
      default: false,
    },
  },

  data() {
    return {
      isOpen: false,
      isShow: false,
    }
  },

  created() {
    this.isShow = this.visible
    this.isOpen = this.visible
  },

  methods: {
    ...mapActions('app', ['showOverlay', 'hideOverlay']),

    close(force = false) {
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
    },

    open() {
      this.isShow = true
      this.showOverlay()

      this.$nextTick(() => {
        this.isOpen = true
        this.$refs.modal.focus()
        this.$emit('open')
      })
    },
  },
}
</script>

<style lang="scss">
@import 'index';
</style>
