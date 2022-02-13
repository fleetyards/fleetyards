<template>
  <div
    :class="{
      'box-large': large,
    }"
    class="box"
  >
    <Panel>
      <div class="box-inner">
        <slot />
      </div>
    </Panel>
    <slot name="footer" />
  </div>
</template>

<script>
import Panel from '@/frontend/core/components/Panel/index.vue'

export default {
  name: 'BoxComponent',

  components: {
    Panel,
  },

  computed: {
    large: {
      type: Boolean,
      default: false,
    },
  },
}
</script>
