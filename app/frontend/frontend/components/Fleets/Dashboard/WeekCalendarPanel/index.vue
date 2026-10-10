<script lang="ts">
export default {
  name: "FleetDashboardWeekCalendarPanel",
};
</script>

<script lang="ts" setup>
import CalendarGrid from "@/frontend/components/Fleets/Events/CalendarGrid/index.vue";
import WeekStrip from "@/frontend/components/Fleets/Dashboard/WeekStrip/index.vue";
import { useMobile } from "@/shared/composables/useMobile";
import type { Fleet, FleetEvent } from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  // From the dashboard's one calendar answer, which covers the week shown.
  events: FleetEvent[];
  loading?: boolean;
};

withDefaults(defineProps<Props>(), {
  loading: false,
});

// Which days are on screen, so the dashboard's one calendar query covers them.
const emit = defineEmits<{ week: [{ start: Date; end: Date }] }>();

// A phone gets the week as a strip of days; the grid's seven columns need the
// width of a desk.
const mobile = useMobile();
</script>

<template>
  <WeekStrip
    v-if="mobile"
    :fleet="fleet"
    :events="events"
    :loading="loading"
    @week="emit('week', $event)"
  />
  <CalendarGrid
    v-else
    :fleet="fleet"
    :events="events"
    view="week"
    compact
    data-test="fleet-dashboard-calendar"
    @update:range="emit('week', $event)"
  />
</template>
