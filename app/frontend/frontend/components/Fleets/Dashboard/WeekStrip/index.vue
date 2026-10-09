<script lang="ts">
export default {
  name: "FleetDashboardWeekStrip",
};
</script>

<script lang="ts" setup>
import { addDays, isSameDay, parseISO, startOfWeek } from "date-fns";
import DashboardPanel from "@/frontend/components/Fleets/Dashboard/DashboardPanel/index.vue";
import EventCard from "@/frontend/components/Fleets/Dashboard/EventCard/index.vue";
import { liveQuery } from "@/frontend/components/Fleets/Dashboard/liveQuery";
import { useToday } from "@/frontend/components/Fleets/Dashboard/useToday";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useI18nStore } from "@/shared/stores/i18n";
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

const { t, l } = useI18n();

const i18nStore = useI18nStore();

/*
 * The week on a phone, the way a phone calendar draws one: all seven days in a
 * strip, a dot under the ones with something on, and the chosen day's events
 * underneath. Seven grid columns at this width leave each day a sliver, and a
 * list of only the busy days reads as if the week had one day in it.
 */
const todayDate = useToday();

const thisWeek = () => startOfWeek(todayDate.value, { weekStartsOn: 1 });

const weekStart = ref(thisWeek());

const selected = ref(todayDate.value);

// Somebody who paged to another week is reading it; only a strip still on the
// current week follows the clock into the next day.
const browsing = ref(false);

watch(todayDate, (now, before) => {
  if (browsing.value) return;

  weekStart.value = thisWeek();
  if (isSameDay(selected.value, before)) selected.value = now;
});

const days = computed(() =>
  Array.from({ length: 7 }, (_, index) => addDays(weekStart.value, index)),
);

const { data } = useFleetCalendar(
  computed(() => props.fleet.slug),
  // From the day before: the calendar answers by start time, and an op that
  // began on Sunday night is still part of Monday.
  computed(() => ({
    from: addDays(weekStart.value, -1).toISOString(),
    to: addDays(weekStart.value, 7).toISOString(),
  })),
  { query: liveQuery },
);

const HIDDEN: FleetEvent["status"][] = [
  FleetEventStatusEnum.DRAFT,
  FleetEventStatusEnum.CANCELLED,
];

const events = computed(() =>
  (data.value?.items ?? []).filter((event) => !HIDDEN.includes(event.status)),
);

// An hour when the event carries no end, as the calendar grid assumes too.
const DEFAULT_DURATION_MS = 60 * 60 * 1000;

// Every day an event touches, not only the one it starts on: an op that runs
// past midnight is on the second day too.
const eventsOn = (day: Date) => {
  const dayStart = day.getTime();
  const dayEnd = addDays(day, 1).getTime();

  return events.value.filter((event) => {
    const start = parseISO(event.startsAt).getTime();
    const end = event.endsAt
      ? parseISO(event.endsAt).getTime()
      : start + DEFAULT_DURATION_MS;

    return start < dayEnd && end > dayStart;
  });
};

const isToday = (day: Date) => isSameDay(day, todayDate.value);

const selectedEvents = computed(() => eventsOn(selected.value));

// Today when the week holds it, otherwise its first day, so moving between
// weeks never leaves the selection on a day that is not drawn.
const showWeek = (start: Date) => {
  weekStart.value = start;
  selected.value = days.value.find((day) => isToday(day)) ?? start;
};

const previous = () => {
  browsing.value = true;
  showWeek(addDays(weekStart.value, -7));
};

const next = () => {
  browsing.value = true;
  showWeek(addDays(weekStart.value, 7));
};

const today = () => {
  browsing.value = false;
  showWeek(thisWeek());
};

const title = computed(() =>
  t("labels.fleets.events.calendar.weekTitle", {
    date: new Intl.DateTimeFormat(i18nStore.locale, {
      month: "short",
      day: "numeric",
    }).format(weekStart.value),
  }),
);

const dayLabel = (day: Date) =>
  new Intl.DateTimeFormat(i18nStore.locale, {
    weekday: "long",
    month: "long",
    day: "numeric",
  }).format(day);
</script>

<template>
  <DashboardPanel :title="title" data-test="fleet-dashboard-week-strip">
    <template #actions>
      <BtnGroup>
        <Btn
          :size="BtnSizesEnum.SM"
          :aria-label="t('actions.previous')"
          @click="previous"
        >
          <i class="fa-light fa-chevron-left" />
        </Btn>
        <Btn
          :size="BtnSizesEnum.SM"
          :aria-label="t('actions.next')"
          @click="next"
        >
          <i class="fa-light fa-chevron-right" />
        </Btn>
        <Btn :size="BtnSizesEnum.SM" @click="today">
          {{ t("actions.today") }}
        </Btn>
      </BtnGroup>
    </template>
    <div class="week-strip" role="group" :aria-label="title">
      <button
        v-for="day in days"
        :key="day.toISOString()"
        type="button"
        class="week-strip__day"
        :class="{
          'week-strip__day--today': isToday(day),
          'week-strip__day--selected': isSameDay(day, selected),
        }"
        :aria-pressed="isSameDay(day, selected)"
        :aria-label="dayLabel(day)"
        data-test="fleet-dashboard-week-day"
        @click="selected = day"
      >
        <span class="week-strip__weekday">
          {{ l(day.toISOString(), "fleetDashboard.formats.weekday") }}
        </span>
        <span class="week-strip__number">
          {{ l(day.toISOString(), "fleetDashboard.formats.day") }}
        </span>
        <span
          class="week-strip__dot"
          :class="{ 'week-strip__dot--on': eventsOn(day).length }"
          aria-hidden="true"
        />
      </button>
    </div>
    <ul v-if="selectedEvents.length" class="week-strip__events">
      <li
        v-for="event in selectedEvents"
        :key="`${event.id}-${event.occurrenceDate ?? ''}`"
        data-test="fleet-dashboard-week-event"
      >
        <EventCard :fleet="fleet" :event="event" />
      </li>
    </ul>
    <p v-else class="week-strip__empty">
      {{ t("fleetDashboard.week.emptyDay", { day: dayLabel(selected) }) }}
    </p>
  </DashboardPanel>
</template>

<style lang="scss" scoped>
.week-strip {
  display: grid;
  grid-template-columns: repeat(7, minmax(0, 1fr));
  gap: 4px;
  margin-bottom: 12px;
}

.week-strip__day {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
  padding: 6px 0;
  border: 1px solid transparent;
  border-radius: var(--radius-control, 8px);
  background: transparent;
  color: var(--color-text, #c8c8c8);
  cursor: pointer;
  line-height: 1.1;
  transition: background-color 150ms ease;

  &:hover,
  &:focus-visible {
    background-color: var(--color-control-hover, rgb(52 58 64 / 0.95));
  }
}

.week-strip__weekday {
  color: var(--color-text-dim, #959595);
  font-size: 10px;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}

.week-strip__number {
  font-size: 17px;
  font-weight: 600;
}

.week-strip__day--today .week-strip__number {
  color: var(--color-primary, #428bca);
}

.week-strip__day--selected {
  border-color: var(--color-edge-soft, rgb(122 130 136 / 0.28));
  background-color: var(--color-control, rgb(39 43 48 / 0.9));
  color: var(--color-lifted, #eee);
}

.week-strip__dot {
  width: 5px;
  height: 5px;
  border-radius: 50%;
  background-color: transparent;
}

.week-strip__dot--on {
  background-color: var(--color-primary, #428bca);
}

.week-strip__events {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.week-strip__empty {
  margin: 0;
  color: var(--color-text-dim, #959595);
}

@media (prefers-reduced-motion: reduce) {
  .week-strip__day {
    transition-duration: 1ms;
  }
}
</style>
