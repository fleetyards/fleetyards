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

<script>
import { mapActions } from 'vuex'
import { displayConfirm } from '@/frontend/lib/Noty'

export default {
  name: 'AppModal',

  data() {
    return {
      component: null,
      fixed: false,
      isOpen: false,
      isShow: false,
      props: null,
      title: null,
      wide: false,
    }
  },

  mounted() {
    this.$comlink.$on('open-modal', this.open)
    this.$comlink.$on('close-modal', this.close)
  },

  beforeDestroy() {
    this.$comlink.$off('open-modal')
    this.$comlink.$off('close-modal')
  },

  methods: {
    ...mapActions('app', ['showOverlay', 'hideOverlay']),

    close(_event, force = false) {
      if (this.fixed && !force) {
        return
      }

      if (this.$refs.modelComponent?.dirty) {
        displayConfirm({
          onConfirm: () => {
            this.internalClose()
          },
          text: this.$t('messages.confirm.modal.dirty'),
        })
      } else {
        this.internalClose()
      }
    },

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
    },

    open(options) {
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
    },
  },
}
</script>
