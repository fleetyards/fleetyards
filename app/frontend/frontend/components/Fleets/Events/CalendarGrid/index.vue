<script lang="ts">
export default {
  name: "FleetEventsCalendarGrid",
};
</script>

<script lang="ts" setup>
import {
  startOfMonth,
  endOfMonth,
  startOfWeek,
  endOfWeek,
  eachDayOfInterval,
  format,
  isSameMonth,
  isSameDay,
  parseISO,
  addMonths,
  subMonths,
} from "date-fns";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import EventStatusBadge from "@/frontend/components/Fleets/Events/EventStatusBadge/index.vue";
import { type Fleet, type FleetEvent } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  fleet: Fleet;
  events: FleetEvent[];
  month: Date;
};

const props = defineProps<Props>();
const emit = defineEmits<{
  "update:month": [Date];
}>();

const { t } = useI18n();

const days = computed(() => {
  const start = startOfWeek(startOfMonth(props.month), { weekStartsOn: 1 });
  const end = endOfWeek(endOfMonth(props.month), { weekStartsOn: 1 });
  return eachDayOfInterval({ start, end });
});

const eventsByDay = computed(() => {
  const map = new Map<string, FleetEvent[]>();
  for (const event of props.events) {
    try {
      const date = format(parseISO(event.startsAt), "yyyy-MM-dd");
      if (!map.has(date)) map.set(date, []);
      map.get(date)!.push(event);
    } catch {
      // skip unparseable
    }
  }
  return map;
});

const eventsForDay = (day: Date): FleetEvent[] => {
  return eventsByDay.value.get(format(day, "yyyy-MM-dd")) ?? [];
};

const monthLabel = computed(() => format(props.month, "MMMM yyyy"));

const weekdayLabels = computed(() => {
  const week = eachDayOfInterval({
    start: startOfWeek(new Date(), { weekStartsOn: 1 }),
    end: endOfWeek(new Date(), { weekStartsOn: 1 }),
  });
  return week.map((d) => format(d, "EEE"));
});

const previousMonth = () => emit("update:month", subMonths(props.month, 1));
const nextMonth = () => emit("update:month", addMonths(props.month, 1));
const today = () => emit("update:month", new Date());

const todayDate = new Date();
</script>

<template>
  <div class="calendar-grid">
    <div class="calendar-grid__nav">
      <Btn :size="BtnSizesEnum.SMALL" inline @click="previousMonth">
        <i class="fa-light fa-chevron-left" />
      </Btn>
      <h3 class="calendar-grid__month">{{ monthLabel }}</h3>
      <Btn :size="BtnSizesEnum.SMALL" inline @click="nextMonth">
        <i class="fa-light fa-chevron-right" />
      </Btn>
      <Btn :size="BtnSizesEnum.SMALL" inline @click="today">
        {{ t("actions.today") }}
      </Btn>
    </div>

    <div class="calendar-grid__weekdays">
      <div
        v-for="(label, idx) in weekdayLabels"
        :key="idx"
        class="calendar-grid__weekday"
      >
        {{ label }}
      </div>
    </div>

    <div class="calendar-grid__days">
      <div
        v-for="day in days"
        :key="day.toISOString()"
        class="calendar-grid__day"
        :class="{
          'calendar-grid__day--out': !isSameMonth(day, props.month),
          'calendar-grid__day--today': isSameDay(day, todayDate),
        }"
      >
        <span class="calendar-grid__day-number">{{ format(day, "d") }}</span>
        <ul class="calendar-grid__events">
          <li
            v-for="event in eventsForDay(day)"
            :key="event.id"
            class="calendar-grid__event"
          >
            <router-link
              :to="{
                name: 'fleet-event',
                params: { slug: props.fleet.slug, event: event.slug },
              }"
              class="calendar-grid__event-link"
            >
              <span class="calendar-grid__event-time">
                {{ format(parseISO(event.startsAt), "HH:mm") }}
              </span>
              <span class="calendar-grid__event-title" :title="event.title">
                {{ event.title }}
              </span>
              <EventStatusBadge :status="event.status" :past="event.past" />
            </router-link>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.calendar-grid {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}
.calendar-grid__nav {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}
.calendar-grid__month {
  margin: 0;
  font-size: 1.1rem;
  flex: 1;
}
.calendar-grid__weekdays {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 0.4rem;
  font-size: 0.8rem;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
.calendar-grid__weekday {
  text-align: center;
  padding: 0.25rem 0;
}
.calendar-grid__days {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 0.4rem;
}
.calendar-grid__day {
  position: relative;
  background: rgba(255, 255, 255, 0.02);
  border: 1px solid rgba(255, 255, 255, 0.05);
  border-radius: 4px;
  min-height: 110px;
  padding: 0.4rem;
  display: flex;
  flex-direction: column;
}
.calendar-grid__day--out {
  opacity: 0.35;
}
.calendar-grid__day--today {
  outline: 1px solid var(--accent, #4aa);
}
.calendar-grid__day-number {
  font-size: 0.8rem;
  color: var(--text-muted);
  margin-bottom: 0.3rem;
}
.calendar-grid__events {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 0.2rem;
  flex: 1;
}
.calendar-grid__event {
  font-size: 0.75rem;
}
.calendar-grid__event-link {
  display: flex;
  align-items: center;
  gap: 0.3rem;
  padding: 0.15rem 0.3rem;
  border-radius: 3px;
  background: rgba(255, 255, 255, 0.05);
  text-decoration: none;
  color: inherit;

  &:hover {
    background: rgba(255, 255, 255, 0.1);
  }
}
.calendar-grid__event-time {
  font-variant-numeric: tabular-nums;
  color: var(--text-muted);
}
.calendar-grid__event-title {
  flex: 1;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
</style>
