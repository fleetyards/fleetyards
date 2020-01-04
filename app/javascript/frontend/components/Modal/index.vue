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
            <a
              class="close"
              aria-label="Close"
              @click="close"
            >
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
      <div
        v-if="$slots['footer']"
        class="modal-footer"
      >
        <slot name="footer" />
        <div class="clearfix" />
      </div>
    </div>
  </div>
</template>

<script>
import Panel from 'frontend/components/Panel'

export default {
  components: {
    Panel,
  },

  props: {
    visible: {
      type: Boolean,
      default: false,
    },

    wide: {
      type: Boolean,
      default: false,
    },

    title: {
      type: String,
      required: true,
    },
  },

  data() {
    return {
      isShow: this.visible,
      isOpen: this.visible,
    }
  },

  methods: {
    open() {
      this.isShow = true
      this.$store.commit('app/showOverlay')

      this.$nextTick(function onOpen() {
        this.isOpen = true
        this.$refs.modal.focus()
        this.$emit('open')
      })
    },

    close() {
      this.isOpen = false
      this.$store.commit('app/hideOverlay')

      this.$nextTick(function onClose() {
        setTimeout(() => {
          this.isShow = false
          this.$emit('close')
        }, 500)
      })
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
