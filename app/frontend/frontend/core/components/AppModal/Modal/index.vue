<template>
  <div class="modal-dialog">
    <Panel :outer-spacing="false">
      <div class="modal-content">
        <div class="modal-header">
          <a class="close" aria-label="Close" @click="close">
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
</template>

<script>
import Panel from '@/frontend/core/components/Panel/index.vue'

export default {
  name: 'ModalComponent',
  components: {
    Panel,
  },

  props: {
    title: {
      required: true,
      type: String,
    },
  },

  methods: {
    close() {
      this.$comlink.$emit('close-modal')
    },
  },
}
</script>
