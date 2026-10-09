<script lang="ts">
export default {
  name: "HangarFloatingProgress",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
</script>

<template>
  <Panel :loading="true" :outer-spacing="false">
    <div class="floating-progress__body">
      <slot />
    </div>
  </Panel>
</template>

<style lang="scss" scoped>
.floating-progress__body {
  display: flex;
  align-items: center;
  gap: 15px;
  padding: 10px 15px;
}
</style>
