<script lang="ts">
export default {
  name: "FleetDashboardUpcomingEventsPanel",
};
</script>

<script lang="ts" setup>
import { liveQuery } from "@/frontend/components/Fleets/Dashboard/liveQuery";
import { addDays, startOfDay } from "date-fns";
import DashboardPanel from "@/frontend/components/Fleets/Dashboard/DashboardPanel/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useMissionCover } from "@/frontend/composables/useMissionCover";
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

// Said to the dashboard once the answer is in, so an empty module can be
// offered as something to start instead of a box saying there is nothing.
const emit = defineEmits<{ empty: [boolean] }>();

const isEmpty = computed(() => !!data.value && !entries.value.length);

watch(isEmpty, (value) => emit("empty", value), { immediate: true });

const { resolve: resolveCover } = useMissionCover();

// Darkest under the date and title, so a bright cover never washes them out.
const SCRIM =
  "linear-gradient(90deg, rgb(0 0 0 / 0.8) 0%, rgb(0 0 0 / 0.45) 55%, rgb(0 0 0 / 0.35) 100%)";

const coverFor = (event: FleetEvent) => ({
  backgroundImage: `${SCRIM}, url(${resolveCover(event)})`,
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
        <!-- The whole card is the link, so the sign-up hint inside it is a
             label rather than a second link nested in the first. -->
        <router-link
          :to="linkFor(event)"
          class="upcoming-events__entry"
          :style="coverFor(event)"
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
            <span class="upcoming-events__title">{{ event.title }}</span>
            <span class="upcoming-events__meta">
              <time :datetime="event.startsAt">
                {{ l(event.startsAt, "datetime.formats.short") }}
              </time>
              <template v-if="event.location">
                · {{ event.location }}
              </template>
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
          <span
            v-else-if="event.signupsOpen"
            class="upcoming-events__signup"
            data-test="fleet-dashboard-event-signup-cta"
          >
            {{ t("fleetDashboard.events.signUp") }}
            <i class="fa-light fa-chevron-right" aria-hidden="true" />
          </span>
        </router-link>
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

.upcoming-events__entry {
  display: flex;
  align-items: center;
  gap: 14px;
  min-width: 0;
  min-height: 64px;
  padding: 10px 14px;
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: var(--radius-control, 8px);
  background-position: center;
  background-size: cover;
  color: #fff;
  text-decoration: none;
  text-shadow: 0 1px 2px rgb(0 0 0 / 0.9);
  transition: filter 150ms ease;

  &:hover,
  &:focus-visible {
    filter: brightness(1.2);
    color: #fff;
  }
}

.upcoming-events__date {
  display: flex;
  flex: 0 0 44px;
  flex-direction: column;
  align-items: center;
  padding: 4px 0;
  background-color: rgb(0 0 0 / 0.55);
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: var(--radius-control, 8px);
  line-height: 1.1;
}

.upcoming-events__weekday {
  color: rgb(255 255 255 / 0.75);
  font-size: 10px;
  letter-spacing: 0.16em;
  text-transform: uppercase;
}

.upcoming-events__day {
  color: #fff;
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
  font-weight: 600;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.upcoming-events__meta {
  overflow: hidden;
  color: rgb(255 255 255 / 0.85);
  font-size: 13px;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.upcoming-events__signup {
  flex: 0 0 auto;
  font-size: 13px;
  white-space: nowrap;
}

@media (prefers-reduced-motion: reduce) {
  .upcoming-events__entry {
    transition-duration: 1ms;
  }
}
</style>
