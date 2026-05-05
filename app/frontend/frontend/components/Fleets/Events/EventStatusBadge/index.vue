<script lang="ts">
export default {
  name: "FleetEventsStatusBadge",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import type { FleetEventStatus } from "@/services/fyApi";

type Props = {
  status: FleetEventStatus;
};

const props = defineProps<Props>();
const { t } = useI18n();

const variantClass = computed(() => `event-status--${props.status}`);
</script>

<template>
  <span class="event-status" :class="variantClass">
    {{ t(`labels.fleets.events.statuses.${props.status}`) }}
  </span>
</template>

<style lang="scss" scoped>
.event-status {
  display: inline-block;
  padding: 0.15rem 0.55rem;
  border-radius: 999px;
  font-size: 0.7rem;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  font-weight: 600;
  border: 1px solid currentColor;
  white-space: nowrap;
}

.event-status--draft {
  color: var(--text-muted);
}
.event-status--open {
  color: var(--success, #4caf50);
}
.event-status--locked {
  color: var(--warning, #ff9800);
}
.event-status--active {
  color: var(--accent, #4aa);
  background: color-mix(in srgb, var(--accent, #4aa) 12%, transparent);
}
.event-status--completed {
  color: var(--text-muted);
  border-style: dashed;
}
.event-status--cancelled {
  color: var(--danger, #c62828);
  border-style: dashed;
}
</style>
