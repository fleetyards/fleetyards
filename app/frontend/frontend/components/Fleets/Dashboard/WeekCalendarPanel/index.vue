<script lang="ts">
export default {
  name: "FleetDashboardWeekCalendarPanel",
};
</script>

<script lang="ts" setup>
import { liveQuery } from "@/frontend/components/Fleets/Dashboard/liveQuery";
import CalendarGrid from "@/frontend/components/Fleets/Events/CalendarGrid/index.vue";
import WeekStrip from "@/frontend/components/Fleets/Dashboard/WeekStrip/index.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { useFleetCalendar, type Fleet } from "@/services/fyApi";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

// A phone gets the week as a strip of days; the grid's seven columns need the
// width of a desk.
const mobile = useMobile();

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
  {
    query: {
      ...liveQuery,
      enabled: computed(() => !mobile.value && !!visibleRange.value),
    },
  },
);

const events = computed(() => data.value?.items ?? []);
</script>

<template>
  <WeekStrip v-if="mobile" :fleet="fleet" />
  <CalendarGrid
    v-else
    :fleet="fleet"
    :events="events"
    view="week"
    compact
    data-test="fleet-dashboard-calendar"
    @update:range="visibleRange = $event"
  />
</template>
