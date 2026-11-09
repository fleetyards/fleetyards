<script lang="ts">
export default {
  name: "StagePanel",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
</script>

<template>
  <Panel translucent :outer-spacing="false" class="stage-panel">
    <div class="stage-panel__body">
      <slot />
    </div>
  </Panel>
</template>

<style lang="scss" scoped>
// Frosted over the stage it floats on.
.stage-panel {
  display: flex;
  flex-direction: column;
  min-height: 0;
  max-height: 100%;
  backdrop-filter: blur(8px);
}

// Content that draws nothing, such as storage with nothing worn that has any,
// takes no frame either.
.stage-panel:has(> .stage-panel__body:empty) {
  display: none;
}

// Scrolled inside the frame: the frame's end-caps sit on its edge, and a
// scrolling frame would count them as overflow.
.stage-panel__body {
  min-height: 0;
  padding: 1rem 1.125rem 1.125rem;
  overflow-y: auto;
}
</style>
