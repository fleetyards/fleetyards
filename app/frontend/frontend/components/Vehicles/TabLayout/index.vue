<script lang="ts">
export default {
  name: "VehicleTabLayout",
};
</script>

<script lang="ts" setup>
// The vehicle tabs' shared frame: the tab's content, and beside it a column for
// what acts on it -- the button that adds to it, the figures that sum it up.
</script>

<template>
  <div class="vehicle-tab-layout">
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
  grid-template-columns: minmax(0, 1fr) 300px;
  gap: 28px;
  align-items: start;

  @media (max-width: $desktop-breakpoint) {
    grid-template-columns: minmax(0, 1fr);
    gap: 20px;
  }

  &__main {
    min-width: 0;
  }

  // First on a phone: the button that adds to a list should not sit under the
  // whole of it.
  &__side {
    position: sticky;
    top: 16px;
    display: flex;
    flex-direction: column;
    gap: 16px;

    @media (max-width: $desktop-breakpoint) {
      position: static;
      order: -1;
    }

    :deep(.metrics-card__body--slim) {
      padding-top: 15px;
    }
  }
}
</style>
