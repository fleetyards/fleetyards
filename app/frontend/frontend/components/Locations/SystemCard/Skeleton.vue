<script lang="ts">
export default {
  name: "LocationSystemCardSkeleton",
};
</script>

<script lang="ts" setup>
type Props = {
  // A card whose system has arrived knows its name, and only waits on the
  // strip.
  withTitle?: boolean;
};

withDefaults(defineProps<Props>(), {
  withTitle: true,
});
</script>

<!-- The shape of a compact strip: the star, then a row of bodies on one
     orbit line, at the strip's own size so nothing moves when it arrives. -->
<template>
  <div class="location-system-skeleton" data-test="system-card-skeleton">
    <span
      v-if="withTitle"
      class="location-system-skeleton__title skeleton-bar"
    />
    <div class="location-system-skeleton__strip">
      <span class="location-system-skeleton__sun skeleton-well" />
      <span
        v-for="index in 4"
        :key="index"
        class="location-system-skeleton__planet skeleton-well"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "@/shared/components/skeleton";

.location-system-skeleton {
  display: flex;
  flex-direction: column;
  gap: 8px;

  &__title {
    width: 140px;
    font-size: 16px;
  }

  &__strip {
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    gap: 28px;
    min-height: 122px;
    padding: 14px 20px;
    background-color: var(--color-control, rgb(39 43 48 / 0.9));
    border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
    border-radius: var(--radius-surface-slim, 12px);
  }

  &__sun,
  &__planet {
    flex-shrink: 0;
    border-radius: 50%;
  }

  &__sun {
    width: 64px;
    height: 64px;
  }

  &__planet {
    width: 44px;
    height: 44px;
  }
}
</style>
