<script lang="ts">
export default {
  name: "HangarSyncProgressCard",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
</script>

<template>
  <Panel :loading="true" :outer-spacing="false">
    <div class="sync-progress-card__body">
      <slot />
    </div>
  </Panel>
</template>

<style lang="scss" scoped>
.sync-progress-card__body {
  display: flex;
  align-items: center;
  gap: 15px;
  padding: 10px 15px;
}
</style>
