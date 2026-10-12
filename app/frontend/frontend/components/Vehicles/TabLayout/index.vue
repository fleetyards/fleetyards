<script lang="ts">
export default {
  name: "VehicleTabLayout",
};
</script>

<script lang="ts" setup>
import { useFeatures } from "@/frontend/composables/useFeatures";
import { FeatureFlagName } from "@/services/fyApi";

// The vehicle tabs' shared frame: the tab's content, and beside it a column for
// what acts on it -- the button that adds to it, the figures that sum it up.
//
// Only with the full-width header: without it the tab navigation already takes
// a column of its own, and a second one would leave the table a sliver.
const { isFeatureEnabled } = useFeatures();

const split = computed(() =>
  isFeatureEnabled(FeatureFlagName.VEHICLE_OVERVIEW),
);
</script>

<template>
  <div
    class="vehicle-tab-layout"
    :class="{ 'vehicle-tab-layout--split': split }"
  >
    <div class="vehicle-tab-layout__main">
      <slot />
    </div>
    <aside class="vehicle-tab-layout__side">
      <slot name="side" />
    </aside>
  </div>
</template>

<style lang="scss" scoped>
.vehicle-tab-layout {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: 20px;
  align-items: start;

  &--split {
    grid-template-columns: minmax(0, 1fr) 300px;
    gap: 28px;

    @media (max-width: $desktop-breakpoint) {
      grid-template-columns: minmax(0, 1fr);
      gap: 20px;
    }
  }

  &__main {
    min-width: 0;
  }

  // Above the content wherever there is one column: the button that adds to a
  // list should not sit under the whole of it.
  &__side {
    display: flex;
    flex-direction: column;
    gap: 16px;
    order: -1;

    :deep(.metrics-card__body--slim) {
      padding-top: 15px;
    }
  }

  &--split &__side {
    position: sticky;
    top: 16px;
    order: 0;

    @media (max-width: $desktop-breakpoint) {
      position: static;
      order: -1;
    }
  }
}
</style>
