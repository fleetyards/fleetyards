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
  past?: boolean;
  variant?: "inline" | "corner";
};

const props = withDefaults(defineProps<Props>(), {
  past: false,
  variant: "inline",
});
const { t } = useI18n();

// Past events that are still in a pre-finished status read as "past" to the
// viewer instead of misleadingly advertising open signups.
const effectiveStatus = computed(() => {
  if (props.past && ["draft", "open", "locked"].includes(props.status)) {
    return "past";
  }
  return props.status;
});

const variantClass = computed(() => [
  `event-status-badge--${effectiveStatus.value}`,
  `event-status-badge--${props.variant}`,
]);
</script>

<template>
  <span class="event-status-badge" :class="variantClass">
    {{ t(`labels.fleets.events.statuses.${effectiveStatus}`) }}
  </span>
</template>

<style lang="scss" scoped>
@import "@/stylesheets/variables.scss";

.event-status-badge {
  display: inline-flex;
  align-items: center;
  font-size: 0.75rem;
  font-weight: 600;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  white-space: nowrap;
  color: #fff;
  background-color: $primary;
  line-height: 1;
}

.event-status-badge--inline {
  padding: 0.3rem 0.7rem;
  border-radius: 6px;
}

.event-status-badge--corner {
  position: absolute;
  top: 120px;
  left: 0;
  height: 32px;
  padding: 0 0.85rem;
  border-radius: 0 10px 10px 0;
  z-index: 2;
}

.event-status-badge--draft {
  background-color: #6c757d;
}
.event-status-badge--open {
  background-color: $success;
}
.event-status-badge--locked {
  background-color: $warning;
}
.event-status-badge--active {
  background-color: $primary;
}
.event-status-badge--completed,
.event-status-badge--past {
  background-color: #495057;
}
.event-status-badge--cancelled {
  background-color: $danger;
}
</style>
