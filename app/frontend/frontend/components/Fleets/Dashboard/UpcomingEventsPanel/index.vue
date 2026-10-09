<script lang="ts">
export default {
  name: "FleetDashboardUpcomingEventsPanel",
};
</script>

<script lang="ts" setup>
import { addDays, startOfDay } from "date-fns";
import DashboardPanel from "@/frontend/components/Fleets/Dashboard/DashboardPanel/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { useI18n } from "@/shared/composables/useI18n";
import {
  FleetEventSignupStatusEnum,
  FleetEventStatusEnum,
  useFleetCalendar,
  type Fleet,
  type FleetEvent,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const { t, l } = useI18n();

const WINDOW_DAYS = 14;
const SHOWN = 6;

// The calendar rather than the event list: it expands a recurring series into
// its dates, where the list would show a weekly op once, on the day it began.
// From the start of today, so an op that is underway is still here, and so the
// query key holds still between renders.
const range = computed(() => {
  const from = startOfDay(new Date());

  return {
    from: from.toISOString(),
    to: addDays(from, WINDOW_DAYS).toISOString(),
  };
});

const { data, isLoading } = useFleetCalendar(
  computed(() => props.fleet.slug),
  range,
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

const linkFor = (event: FleetEvent) => ({
  name: "fleet-event",
  params: {
    slug: props.fleet.slug,
    event: event.parentEventSlug || event.slug,
  },
  query: event.occurrenceDate
    ? { occurrence: event.occurrenceDate }
    : undefined,
});

const SIGNUP_VARIANTS: Record<string, `${PillVariantsEnum}`> = {
  [FleetEventSignupStatusEnum.CONFIRMED]: PillVariantsEnum.SUCCESS,
  [FleetEventSignupStatusEnum.TENTATIVE]: PillVariantsEnum.WARNING,
  [FleetEventSignupStatusEnum.INTERESTED]: PillVariantsEnum.NEUTRAL,
  [FleetEventSignupStatusEnum.PENDING]: PillVariantsEnum.NEUTRAL,
};
</script>

<template>
  <DashboardPanel
    :title="t('fleetDashboard.events.title')"
    :loading="isLoading"
    :empty="!entries.length"
    :empty-text="t('fleetDashboard.events.empty')"
    :more="{ name: 'fleet-events', params: { slug: fleet.slug } }"
    data-test="fleet-dashboard-events"
  >
    <ul class="upcoming-events">
      <li
        v-for="event in entries"
        :key="`${event.id}-${event.occurrenceDate ?? ''}`"
        class="upcoming-events__entry"
        data-test="fleet-dashboard-event"
      >
        <div class="upcoming-events__date" aria-hidden="true">
          <span class="upcoming-events__weekday">
            {{ l(event.startsAt, "fleetDashboard.formats.weekday") }}
          </span>
          <span class="upcoming-events__day">
            {{ l(event.startsAt, "fleetDashboard.formats.day") }}
          </span>
        </div>
        <div class="upcoming-events__text">
          <router-link :to="linkFor(event)" class="upcoming-events__title">
            {{ event.title }}
          </router-link>
          <span class="upcoming-events__meta">
            <time :datetime="event.startsAt">
              {{ l(event.startsAt, "datetime.formats.short") }}
            </time>
            <template v-if="event.location"> · {{ event.location }}</template>
          </span>
        </div>
        <Pill
          v-if="event.viewerSignup"
          :variant="SIGNUP_VARIANTS[event.viewerSignup.status]"
          data-test="fleet-dashboard-event-signup"
        >
          {{
            t(
              `labels.fleets.events.signupStatuses.${event.viewerSignup.status}`,
            )
          }}
        </Pill>
        <router-link
          v-else-if="event.signupsOpen"
          :to="linkFor(event)"
          class="upcoming-events__signup"
          data-test="fleet-dashboard-event-signup-cta"
        >
          {{ t("fleetDashboard.events.signUp") }}
        </router-link>
      </li>
    </ul>
  </DashboardPanel>
</template>

<style lang="scss" scoped>
.upcoming-events {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.upcoming-events__entry {
  display: flex;
  align-items: center;
  gap: 14px;
  min-width: 0;
}

.upcoming-events__date {
  display: flex;
  flex: 0 0 44px;
  flex-direction: column;
  align-items: center;
  padding: 4px 0;
  background-color: var(--color-control, rgb(39 43 48 / 0.9));
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: var(--radius-control, 8px);
  line-height: 1.1;
}

.upcoming-events__weekday {
  color: var(--color-text-dim, #959595);
  font-size: 10px;
  letter-spacing: 0.16em;
  text-transform: uppercase;
}

.upcoming-events__day {
  color: var(--color-lifted, #eee);
  font-size: 18px;
  font-weight: 600;
}

.upcoming-events__text {
  display: flex;
  flex: 1 1 auto;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.upcoming-events__title {
  overflow: hidden;
  color: var(--color-lifted, #eee);
  font-weight: 600;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.upcoming-events__meta {
  overflow: hidden;
  color: var(--color-text-dim, #959595);
  font-size: 13px;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.upcoming-events__signup {
  flex: 0 0 auto;
  font-size: 13px;
}
</style>
