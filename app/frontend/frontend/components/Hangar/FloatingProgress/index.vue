<script lang="ts">
export default {
  name: "HangarFloatingProgress",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import { useMobile } from "@/shared/composables/useMobile";

const mobile = useMobile();
</script>

<template>
  <div
    class="floating-progress"
    :class="{ 'floating-progress--mobile': mobile }"
  >
    <Panel :loading="true" :outer-spacing="false">
      <div class="floating-progress__body">
        <slot />
      </div>
    </Panel>
  </div>
</template>

<style lang="scss" scoped>
// Below AppModal (1050), so a modal opened meanwhile covers it. The hangar
// sync and the buy-back price pass never run together, so they share the spot.
.floating-progress {
  position: fixed;
  right: calc(20px + env(safe-area-inset-right));
  bottom: calc(20px + env(safe-area-inset-bottom));
  z-index: 1040;
  max-width: calc(100vw - 40px);
}

// Above the mobile navigation, which is fixed along the bottom edge.
.floating-progress--mobile {
  bottom: calc(
    #{$navigation-mobile-height + $navigation-mobile-bottom-offset + 20px} +
      env(safe-area-inset-bottom)
  );
}

.floating-progress__body {
  display: flex;
  align-items: center;
  gap: 15px;
  padding: 10px 15px;
}
</style>
