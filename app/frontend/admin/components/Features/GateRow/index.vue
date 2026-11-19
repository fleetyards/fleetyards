<script lang="ts">
export default {
  name: "FeatureGateRow",
};
</script>

<script lang="ts" setup>
type Props = {
  label: string;
  hint: string;
};

defineProps<Props>();
</script>

<template>
  <div class="feature-gate-row">
    <div class="feature-gate-row__text">
      <h3 class="feature-gate-row__label">{{ label }}</h3>
      <p class="feature-gate-row__hint">{{ hint }}</p>
    </div>
    <div class="feature-gate-row__control">
      <slot />
    </div>
  </div>
</template>

<style lang="scss" scoped>
.feature-gate-row {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: 0.625rem 2rem;
  padding: 1.5rem 0;
  border-bottom: 1px solid var(--color-edge-faint);

  &:first-child {
    padding-top: 0.25rem;
  }

  &:last-child {
    padding-bottom: 0.25rem;
    border-bottom: 0;
  }

  @media (min-width: $desktop-breakpoint) {
    grid-template-columns: minmax(0, 220px) minmax(0, 1fr);
  }
}

.feature-gate-row__label {
  margin: 0 0 0.25rem;
  font-size: 15px;
  font-weight: 600;
  color: var(--color-lifted);
}

.feature-gate-row__hint {
  margin: 0;
  font-size: 13px;
  color: var(--color-text-dim);
}

.feature-gate-row__control {
  min-width: 0;
}
</style>
