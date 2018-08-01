<template>
  <div
    :class="{
      'box-large': large
    }"
    class="box"
  >
    <Panel>
      <div class="box-inner">
        <slot />
      </div>
    </Panel>
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

<style lang="scss" scoped>
  @import "./styles/index";
</style>
