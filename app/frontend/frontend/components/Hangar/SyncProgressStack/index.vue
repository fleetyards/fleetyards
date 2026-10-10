<script lang="ts">
export default {
  name: "HangarSyncProgressStack",
};
</script>

<script lang="ts" setup>
import HangarBuybackSyncProgress from "@/frontend/components/Hangar/BuybackSyncProgress/index.vue";
import HangarSyncProgress from "@/frontend/components/Hangar/SyncProgress/index.vue";
import { useMobile } from "@/shared/composables/useMobile";

const mobile = useMobile();
</script>

<template>
  <div
    class="sync-progress-stack"
    :class="{ 'sync-progress-stack--mobile': mobile }"
  >
    <HangarSyncProgress />
    <HangarBuybackSyncProgress />
  </div>
</template>

<style lang="scss" scoped>
// Both syncs can run at once, so their cards stack rather than share a spot.
// Below AppModal (1050), so a modal opened meanwhile covers them.
.sync-progress-stack {
  position: fixed;
  right: calc(20px + env(safe-area-inset-right));
  bottom: calc(20px + env(safe-area-inset-bottom));
  z-index: 1040;
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 10px;
  max-width: calc(100vw - 40px);
}

// Above the mobile navigation, which is fixed along the bottom edge.
.sync-progress-stack--mobile {
  bottom: calc(
    #{$navigation-mobile-height + $navigation-mobile-bottom-offset + 20px} +
      env(safe-area-inset-bottom)
  );
}
</style>
