<script lang="ts">
export default {
  name: "FleetDashboardUpcomingEventsPanel",
};
</script>

<script lang="ts" setup>
import { addDays } from "date-fns";
import { useToday } from "@/frontend/components/Fleets/Dashboard/useToday";
import DashboardPanel from "@/frontend/components/Fleets/Dashboard/DashboardPanel/index.vue";
import EventCard from "@/frontend/components/Fleets/Dashboard/EventCard/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  FleetEventStatusEnum,
  type Fleet,
  type FleetEvent,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  // From the dashboard's one calendar answer, which reaches at least two
  // weeks ahead. Undefined until it is in.
  events?: FleetEvent[];
  loading?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  events: undefined,
  loading: false,
});

const { t } = useI18n();

const WINDOW_DAYS = 14;
const SHOWN = 6;

const today = useToday();

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

// What has not ended yet and starts within the window: the answer may reach
// further back or ahead, for the week on screen.
const entries = computed(() => {
  const now = Date.now();
  const until = addDays(today.value, WINDOW_DAYS).getTime();

  return (props.events ?? [])
    .filter(
      (event) =>
        !HIDDEN.includes(event.status) &&
        endsAt(event) >= now &&
        new Date(event.startsAt).getTime() < until,
    )
    .slice(0, SHOWN);
});

// Said to the dashboard once the answer is in, so an empty module can be
// offered as something to start instead of a box saying there is nothing.
const emit = defineEmits<{ empty: [boolean] }>();

const isEmpty = computed(() => !!props.events && !entries.value.length);

watch(isEmpty, (value) => emit("empty", value), { immediate: true });
</script>

<template>
  <DashboardPanel
    v-if="entries.length"
    :title="t('fleetDashboard.events.title')"
    :loading="loading"
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
