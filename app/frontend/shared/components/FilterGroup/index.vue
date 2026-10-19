<script lang="ts">
export default { name: "FilterGroup" };
</script>

<script lang="ts" setup>
withDefaults(
  defineProps<{
    label: string;
    active?: boolean;
    defaultOpen?: boolean;
  }>(),
  { active: false, defaultOpen: false },
);
</script>

<template>
  <details class="filter-group" :open="active || defaultOpen">
    <summary class="filter-group__heading">
      {{ label
      }}<span
        v-if="active"
        class="filter-group__indicator"
        aria-hidden="true"
      />
    </summary>
    <div class="filter-group__content"><slot /></div>
  </details>
</template>

<style lang="scss" scoped>
.filter-group {
  border-bottom: 1px solid var(--color-border, #{$gray});
  margin-bottom: 16px;

  &__heading {
    cursor: pointer;
    padding: 12px 0;
    font-weight: 600;
  }

  &__indicator {
    display: inline-block;
    width: 6px;
    height: 6px;
    border-radius: 50%;
    background: var(--color-primary, #{$primary});
    margin-left: 8px;
  }

  &__content {
    padding-top: 8px;
  }
}
</style>
