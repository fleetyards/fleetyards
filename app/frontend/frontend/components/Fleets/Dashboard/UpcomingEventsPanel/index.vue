<script lang="ts">
export default {
  name: "FleetDashboardUpcomingEventsPanel",
};
</script>

<script lang="ts" setup>
import { liveQuery } from "@/frontend/components/Fleets/Dashboard/liveQuery";
import { addDays } from "date-fns";
import { useToday } from "@/frontend/components/Fleets/Dashboard/useToday";
import DashboardPanel from "@/frontend/components/Fleets/Dashboard/DashboardPanel/index.vue";
import EventCard from "@/frontend/components/Fleets/Dashboard/EventCard/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  FleetEventStatusEnum,
  useFleetCalendar,
  type Fleet,
  type FleetEvent,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const { t } = useI18n();

const WINDOW_DAYS = 14;
const SHOWN = 6;

const today = useToday();

// The calendar rather than the event list: it expands a recurring series into
// its dates, where the list would show a weekly op once, on the day it began.
// From the start of yesterday, because the calendar answers by start time and
// an op that began last night may still be running; what has ended is dropped
// below. Whole days, so the query key holds still between renders.
const range = computed(() => ({
  from: addDays(today.value, -1).toISOString(),
  to: addDays(today.value, WINDOW_DAYS).toISOString(),
}));

const { data, isLoading } = useFleetCalendar(
  computed(() => props.fleet.slug),
  range,
  { query: liveQuery },
);

const HIDDEN: FleetEvent["status"][] = [
  FleetEventStatusEnum.DRAFT,
  FleetEventStatusEnum.CANCELLED,
  FleetEventStatusEnum.COMPLETED,
];

// An hour when the event carries no end, as the calendar grid assumes too.
const DEFAULT_DURATION_MS = 60 * 60 * 1000;

const endsAt = (event: FleetEvent) =>
  event.endsAt
    ? new Date(event.endsAt).getTime()
    : new Date(event.startsAt).getTime() + DEFAULT_DURATION_MS;

const entries = computed(() => {
  const now = Date.now();

  return (data.value?.items ?? [])
    .filter((event) => !HIDDEN.includes(event.status) && endsAt(event) >= now)
    .slice(0, SHOWN);
});

// Said to the dashboard once the answer is in, so an empty module can be
// offered as something to start instead of a box saying there is nothing.
const emit = defineEmits<{ empty: [boolean] }>();

const isEmpty = computed(() => !!data.value && !entries.value.length);

watch(isEmpty, (value) => emit("empty", value), { immediate: true });
</script>

<template>
  <DashboardPanel
    v-if="entries.length"
    :title="t('fleetDashboard.events.title')"
    :loading="isLoading"
    :more="{ name: 'fleet-events', params: { slug: fleet.slug } }"
    data-test="fleet-dashboard-events"
  >
    <ul class="upcoming-events">
      <li
        v-for="event in entries"
        :key="`${event.id}-${event.occurrenceDate ?? ''}`"
        data-test="fleet-dashboard-event"
      >
        <EventCard :fleet="fleet" :event="event" />
      </li>
    </ul>
  </DashboardPanel>
</template>

<style lang="scss" scoped>
.upcoming-events {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin: 0;
  padding: 0;
  list-style: none;
}
</style>
