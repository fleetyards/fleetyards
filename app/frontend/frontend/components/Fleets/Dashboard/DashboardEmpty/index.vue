<script lang="ts">
export default {
  name: "FleetDashboardEmpty",
};
</script>

<script lang="ts" setup>
type Props = {
  icon: string;
  title: string;
  hint?: string;
};

withDefaults(defineProps<Props>(), {
  hint: undefined,
});
</script>

<template>
  <div class="dashboard-empty" data-test="fleet-dashboard-empty">
    <i
      :class="['fa-light', icon, 'dashboard-empty__icon']"
      aria-hidden="true"
    />
    <div class="dashboard-empty__text">
      <span class="dashboard-empty__title">{{ title }}</span>
      <span v-if="hint" class="dashboard-empty__hint">{{ hint }}</span>
    </div>
    <div v-if="$slots.default" class="dashboard-empty__action">
      <slot />
    </div>
  </div>
</template>

<style lang="scss" scoped>
.dashboard-empty {
  display: flex;
  align-items: center;
  gap: 14px;
  min-width: 0;
}

.dashboard-empty__icon {
  flex: 0 0 24px;
  color: var(--color-muted, #7a8288);
  font-size: 20px;
  text-align: center;
}

.dashboard-empty__text {
  display: flex;
  flex: 1 1 auto;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.dashboard-empty__title {
  color: var(--color-lifted, #eee);
  font-weight: 600;
}

.dashboard-empty__hint {
  color: var(--color-text-dim, #959595);
  font-size: 13px;
}

.dashboard-empty__action {
  flex: 0 0 auto;
  font-size: 13px;
  white-space: nowrap;
}
</style>
