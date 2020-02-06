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
import Panel from 'frontend/components/Panel'

export default {
  components: {
    Panel,
  },
  props: {
    large: {
      type: Boolean,
      default: false,
    },
  },
}
</script>
