<script lang="ts">
export default { name: "FilterGroup" };
</script>

<script lang="ts" setup>
import Collapsed from "@/shared/components/Collapsed.vue";

const props = withDefaults(
  defineProps<{
    label: string;
    active?: boolean;
    defaultOpen?: boolean;
  }>(),
  { active: false, defaultOpen: false },
);

const expanded = ref(props.active || props.defaultOpen);

// A filter set from outside the panel - a link, a removed chip's neighbour -
// should not end up hidden inside a closed group.
watch(
  () => props.active,
  (active) => {
    if (active) expanded.value = true;
  },
);

const contentId = `filter-group-${useId()}`;
</script>

<template>
  <div class="filter-group">
    <hr class="filter-group__divider" />
    <button
      type="button"
      class="filter-group__heading"
      :aria-expanded="expanded"
      :aria-controls="contentId"
      @click="expanded = !expanded"
    >
      <span class="filter-group__label" :title="label">{{ label }}</span>
      <span v-if="active" class="filter-group__indicator" aria-hidden="true" />
      <i
        class="fa-solid fa-chevron-down filter-group__chevron"
        aria-hidden="true"
      />
    </button>
    <Collapsed :id="contentId" :visible="expanded" :duration="200">
      <slot />
    </Collapsed>
  </div>
</template>

<style lang="scss" scoped>
@import "@/shared/components/rowLabel";

.filter-group {
  &:not(.filter-group + .filter-group) > .filter-group__divider {
    display: none;
  }

  &:has(+ :not(.filter-group)) {
    margin-bottom: 8px;
  }

  &__heading {
    display: flex;
    align-items: center;
    gap: 8px;
    width: 100%;
    margin: 0;
    padding: 0 0 14px;
    border: 0;
    background: none;
    color: inherit;
    text-align: left;
    cursor: pointer;

    &:focus-visible {
      outline: 2px solid var(--color-primary, #{$primary});
      outline-offset: 2px;
      border-radius: 2px;
    }
  }

  &__label {
    @include row-label;

    min-width: 0;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;

    transition: color 150ms ease-in-out;
  }

  &__heading:hover &__label,
  &__heading[aria-expanded="true"] &__label {
    color: var(--color-lifted, #eee);
  }

  &__indicator {
    flex-shrink: 0;
    width: 6px;
    height: 6px;
    border-radius: 50%;
    background: var(--color-primary, #{$primary});
  }

  &__chevron {
    margin-left: auto;
    font-size: 11px;
    color: var(--color-muted, #7a8288);
    transition: transform 150ms ease-in-out;
  }

  &__heading[aria-expanded="true"] &__chevron {
    transform: rotate(180deg);
  }
}

@media (prefers-reduced-motion: reduce) {
  .filter-group__label,
  .filter-group__chevron {
    transition-duration: 1ms;
  }
}
</style>
