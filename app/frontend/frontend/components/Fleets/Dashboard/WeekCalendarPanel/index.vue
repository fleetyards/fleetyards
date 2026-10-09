<script lang="ts">
export default {
  name: "FleetDashboardWeekCalendarPanel",
};
</script>

<script lang="ts" setup>
import CalendarGrid from "@/frontend/components/Fleets/Events/CalendarGrid/index.vue";
import { useFleetCalendar, type Fleet } from "@/services/fyApi";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const visibleRange = ref<{ start: Date; end: Date } | null>(null);

const { data } = useFleetCalendar(
  computed(() => props.fleet.slug),
  computed(() =>
    visibleRange.value
      ? {
          from: visibleRange.value.start.toISOString(),
          to: visibleRange.value.end.toISOString(),
        }
      : {},
  ),
  { query: { enabled: computed(() => !!visibleRange.value) } },
);

const events = computed(() => data.value?.items ?? []);
</script>

<template>
  <CalendarGrid
    :fleet="fleet"
    :events="events"
    view="week"
    compact
    data-test="fleet-dashboard-calendar"
    @update:range="visibleRange = $event"
  />
</template>
