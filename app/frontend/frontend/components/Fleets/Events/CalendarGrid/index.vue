<script lang="ts">
export default {
  name: "FleetEventsCalendarGrid",
};
</script>

<script lang="ts" setup>
import {
  createCalendar,
  destroyCalendar,
  DayGrid,
  TimeGrid,
  Interaction,
  type EventCalendarInstance,
} from "@event-calendar/core";
import "@event-calendar/core/index.css";
import { MissionCategory } from "@/services/fyApi";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { type Fleet, type FleetEvent } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useI18nStore } from "@/shared/stores/i18n";
import { useMissionCover } from "@/frontend/composables/useMissionCover";
import { useRouter } from "vue-router";
import { format, parseISO } from "date-fns";

type CalendarViewKind = "month" | "week";

type Props = {
  fleet: Fleet;
  events: FleetEvent[];
  view?: CalendarViewKind;
};

const props = withDefaults(defineProps<Props>(), {
  view: "month",
});
const emit = defineEmits<{
  "update:range": [{ start: Date; end: Date }];
  "update:view": [CalendarViewKind];
  "create-event": [Date];
}>();

const { t } = useI18n();
const i18nStore = useI18nStore();
const router = useRouter();
const { resolve: resolveCover } = useMissionCover();

const calendarEl = ref<HTMLElement | null>(null);
let ec: EventCalendarInstance | null = null;

type CalendarLibView = "dayGridMonth" | "timeGridWeek";

const toLibView = (v: CalendarViewKind): CalendarLibView =>
  v === "week" ? "timeGridWeek" : "dayGridMonth";

const route = useRoute();

const initialDate = (() => {
  const q = route.query.date;
  if (typeof q === "string") {
    const parsed = parseISO(q);
    if (!isNaN(parsed.getTime())) return parsed;
  }
  return new Date();
})();

const titleLabel = ref("");

type CategoryStyle = { icon: string; color: string };

const categoryStyles: Record<string, CategoryStyle> = {
  [MissionCategory.other]: { icon: "fa-circle-question", color: "#7a8288" },
  [MissionCategory.ship_combat]: { icon: "fa-rocket", color: "#dc3545" },
  [MissionCategory.ground_combat]: { icon: "fa-burst", color: "#fa6800" },
  [MissionCategory.combined_combat]: {
    icon: "fa-crosshairs",
    color: "#c0392b",
  },
  [MissionCategory.mining]: { icon: "fa-gem", color: "#d4af37" },
  [MissionCategory.salvage]: { icon: "fa-recycle", color: "#16a085" },
  [MissionCategory.cargo_hauling]: { icon: "fa-box", color: "#428bca" },
  [MissionCategory.exploration]: { icon: "fa-compass", color: "#9b59b6" },
};

const styleFor = (category?: string | null): CategoryStyle =>
  (category && categoryStyles[category]) ||
  categoryStyles[MissionCategory.other];

const buildCalendarEvent = (event: FleetEvent) => ({
  id: event.slug,
  start: event.startsAt,
  end: event.endsAt ?? undefined,
  title: event.title,
  extendedProps: { fleetEvent: event },
});

const calendarEvents = computed(() => props.events.map(buildCalendarEvent));

const renderEventChip = (info: {
  event: { extendedProps?: { fleetEvent?: FleetEvent }; title: string };
  timeText: string;
  view: { type: string };
}) => {
  const event = info.event.extendedProps?.fleetEvent;
  const isMonth = info.view.type === "dayGridMonth";

  const chip = document.createElement("div");
  chip.className = "fy-event-chip";

  if (isMonth) {
    chip.classList.add("fy-event-chip--compact");
    const { icon, color } = styleFor(event?.category as string | undefined);
    chip.style.setProperty("--chip-color", color);

    const iconEl = document.createElement("i");
    iconEl.className = `fa-light ${icon} fy-event-chip__icon`;
    chip.appendChild(iconEl);
  } else {
    const cover = event ? resolveCover(event) : null;
    if (cover) {
      chip.style.backgroundImage = `url(${cover})`;
      chip.classList.add("fy-event-chip--with-cover");
    }
  }

  if (info.timeText) {
    const time = document.createElement("span");
    time.className = "fy-event-chip__time";
    time.textContent = info.timeText;
    chip.appendChild(time);
  }

  const title = document.createElement("span");
  title.className = "fy-event-chip__title";
  title.textContent = info.event.title;
  chip.appendChild(title);

  return { domNodes: [chip] };
};

const updateTitle = () => {
  const date = ec?.getOption("date") as Date | string | undefined;
  if (!date) return;
  const d = date instanceof Date ? date : new Date(date);
  const locale = i18nStore.locale;
  if (props.view === "week") {
    const formatted = new Intl.DateTimeFormat(locale, {
      month: "short",
      day: "numeric",
      year: "numeric",
    }).format(d);
    titleLabel.value = t("labels.fleets.events.calendar.weekTitle", {
      date: formatted,
    });
  } else {
    titleLabel.value = new Intl.DateTimeFormat(locale, {
      month: "long",
      year: "numeric",
    }).format(d);
  }
};

// One-way: calendar drives the `date` query param. We never watch it back
// onto the calendar (would create a feedback loop with datesSet).
const syncDateToUrl = () => {
  const date = ec?.getOption("date") as Date | string | undefined;
  if (!date) return;
  const d = date instanceof Date ? date : new Date(date);
  const formatted = format(d, "yyyy-MM-dd");
  if (route.query.date === formatted) return;
  void router.replace({
    query: { ...route.query, date: formatted },
  });
};

const goPrev = () => {
  ec?.prev();
};
const goNext = () => {
  ec?.next();
};
const goToday = () => {
  ec?.setOption("date", new Date());
};
const setView = (view: CalendarViewKind) => {
  if (props.view === view) return;
  emit("update:view", view);
};

onMounted(() => {
  if (!calendarEl.value) return;

  ec = createCalendar(calendarEl.value, [DayGrid, TimeGrid, Interaction], {
    view: toLibView(props.view),
    date: initialDate,
    events: calendarEvents.value,
    locale: i18nStore.locale,
    firstDay: 1,
    headerToolbar: false,
    height: "auto",
    dayMaxEvents: true,
    nowIndicator: true,
    selectable: true,
    selectMirror: true,
    slotDuration: "01:00:00",
    slotHeight: 56,
    slotMinTime: "08:00:00",
    slotMaxTime: "24:00:00",
    eventClick: (info: {
      event: { extendedProps?: { fleetEvent?: FleetEvent } };
    }) => {
      const event = info.event.extendedProps?.fleetEvent;
      if (event?.slug) {
        void router.push({
          name: "fleet-event",
          params: { slug: props.fleet.slug, event: event.slug },
        });
      }
    },
    dateClick: (info: { date: Date }) => {
      emit("create-event", info.date);
    },
    select: (info: { start: Date }) => {
      emit("create-event", info.start);
    },
    datesSet: (info: { start: Date; end: Date }) => {
      emit("update:range", { start: info.start, end: info.end });
      updateTitle();
      syncDateToUrl();
    },
    eventContent: renderEventChip,
  });

  updateTitle();
});

watch(
  () => props.view,
  (next) => {
    ec?.setOption("view", toLibView(next));
    updateTitle();
  },
);

watch(
  () => i18nStore.locale,
  (locale) => {
    ec?.setOption("locale", locale);
    updateTitle();
  },
);

watch(
  calendarEvents,
  (events) => {
    if (ec) ec.setOption("events", events);
  },
  { flush: "post" },
);

// Note: no `watch(() => props.month, …)` here. The calendar owns its own
// date state once mounted; `datesSet` already broadcasts changes upward.
// Watching props.month and writing it back via setOption creates a feedback
// loop that reverses every prev/next click.

onUnmounted(() => {
  if (ec) {
    destroyCalendar(ec);
    ec = null;
  }
});
</script>

<template>
  <Panel slim>
    <PanelBody no-padding rounded="all">
      <div class="fy-calendar__toolbar">
        <BtnGroup>
          <Btn :size="BtnSizesEnum.SMALL" inline @click="goPrev">
            <i class="fa-light fa-chevron-left" />
          </Btn>
          <Btn :size="BtnSizesEnum.SMALL" inline @click="goNext">
            <i class="fa-light fa-chevron-right" />
          </Btn>
          <Btn :size="BtnSizesEnum.SMALL" inline @click="goToday">
            {{ t("actions.today") }}
          </Btn>
        </BtnGroup>
        <h3 class="fy-calendar__title">{{ titleLabel }}</h3>
        <BtnGroup>
          <Btn
            :size="BtnSizesEnum.SMALL"
            inline
            :active="props.view === 'month'"
            @click="setView('month')"
          >
            {{ t("labels.fleets.events.calendar.month") }}
          </Btn>
          <Btn
            :size="BtnSizesEnum.SMALL"
            inline
            :active="props.view === 'week'"
            @click="setView('week')"
          >
            {{ t("labels.fleets.events.calendar.week") }}
          </Btn>
        </BtnGroup>
      </div>
      <div ref="calendarEl" class="fy-calendar__body ec-dark" />
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
.fy-calendar__toolbar {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 0.85rem 1rem;
  background: rgba(#000, 0.25);
  border-bottom: 1px solid rgba(#c8c8c8, 0.1);
}

.fy-calendar__title {
  flex: 1;
  margin: 0;
  font-size: 1.05rem;
  text-align: center;
  color: $text-color;
}

.fy-calendar__body {
  // Override library CSS variables so the calendar adopts the app palette
  // instead of the library's stock dark palette. .ec-dark above wires the
  // dark variant on as a starting point.
  :deep(.ec) {
    --ec-bg-color: #{$panel-bg};
    --ec-border-color: rgba(#c8c8c8, 0.22);
    --ec-text-color: #{$text-color};
    --ec-today-bg-color: rgba($primary, 0.32);
    --ec-highlight-color: rgba($primary, 0.25);
    --ec-event-bg-color: transparent;
    --ec-event-text-color: white;

    background: transparent;
    color: $text-color;
  }

  // Under-header separator (in both views). .ec-col-head ships with a 1px
  // bottom border via --ec-border-color; bumping its visibility here.
  :deep(.ec-col-head),
  :deep(.ec-header .ec-sidebar),
  :deep(.ec-header .ec-day-head),
  :deep(.ec-time-grid .ec-all-day) {
    border-bottom: 1px solid rgba(#c8c8c8, 0.4);
  }

  :deep(.ec-day-grid .ec-day) {
    --ec-day-bg-color: rgba(#000, 0.18);
    min-block-size: 7em;
    padding: 0.5rem;
    border: 1px solid rgba(#c8c8c8, 0.22);
    border-block-start: none;
    border-inline-start: none;

    &.ec-other-month {
      opacity: 0.4;
    }
  }

  // Today highlight: just the day-number gets a primary-color pill in
  // month view; in week view, the column header (Mon 08/05) keeps a
  // subtle full-cell tint since the date there isn't a separate element.
  :deep(.ec-day-grid .ec-day.ec-today) {
    background-color: transparent !important;
    box-shadow: none;
  }

  :deep(.ec-day-grid .ec-day.ec-today .ec-day-head time) {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    min-inline-size: 1.6em;
    block-size: 1.6em;
    padding: 0 0.45em;
    border-radius: 999px;
    background-color: $primary;
    color: white;
    font-weight: 600;
  }

  :deep(.ec-col-head.ec-today) {
    background-color: rgba($primary, 0.18) !important;
    box-shadow: inset 0 -2px 0 0 $primary;
  }

  // Week view: a) vertical day separators, b) horizontal hour lines.
  // Library renders hour lines via a gradient on each .ec-day that mixes
  // --ec-day-bg-color (mask) with --ec-border-color (line). Replace it
  // with a single explicit gradient so the lines render reliably regardless
  // of how transparent we make the day background.
  :deep(.ec-time-grid .ec-day) {
    --ec-day-bg-color: rgba(#000, 0.12);
    background-color: var(--ec-day-bg-color);
    background-image: repeating-linear-gradient(
      to bottom,
      transparent 0,
      transparent calc(var(--ec-slot-height) - 1px),
      rgba(#c8c8c8, 0.22) calc(var(--ec-slot-height) - 1px),
      rgba(#c8c8c8, 0.22) var(--ec-slot-height)
    );
    background-size: 100% var(--ec-slot-height);
    border: 1px solid rgba(#c8c8c8, 0.22);
    border-block-start: none;
    border-inline-start: none;
  }

  :deep(.ec-day-grid.ec-month-view .ec-day-head) {
    padding: 0.15rem 0.4rem 0.85rem;
    flex-direction: row;
    justify-content: center;
  }

  :deep(.ec-days .ec-day-head) {
    padding: 0.6rem 0.75rem;
    background: rgba(#000, 0.2);
    border-bottom: 1px solid rgba(#c8c8c8, 0.12);
    text-transform: uppercase;
    letter-spacing: 0.05em;
    font-size: 0.75rem;
    color: color.adjust($text-color, $lightness: -10%);
  }

  :deep(.ec-day-head time),
  :deep(.ec-time) {
    color: color.adjust($text-color, $lightness: -10%);
    font-size: 0.8rem;
  }

  // Library's .ec-event provides padding + background. We zero out the
  // padding so our chip can fill the whole event card; the chip itself
  // paints background (cover image or solid primary).
  :deep(.ec-event) {
    padding: 0;
    overflow: hidden;
  }

  :deep(.fy-event-chip) {
    display: flex;
    width: 100%;
    padding: 0.18rem 0.4rem;
    border-radius: 3px;
    background-color: rgba($primary, 0.85);
    background-size: cover;
    background-position: center;
    background-repeat: no-repeat;
    color: white;
    font-size: 0.85rem;
    line-height: 1.3;
    overflow: hidden;
    cursor: pointer;
    box-sizing: border-box;
    gap: 0.3rem;
  }

  // Month view: compact one-liner with category icon + tint, no cover image.
  :deep(.ec-day-grid .fy-event-chip) {
    flex-direction: row;
    justify-content: flex-start;
    align-items: center;
  }

  :deep(.fy-event-chip--compact) {
    background-image: none !important;
    background-color: color-mix(
      in srgb,
      var(--chip-color, #{$primary}) 18%,
      transparent
    );
    border-inline-start: 3px solid var(--chip-color, #{$primary});
    color: $text-color;
    text-shadow: none;
    box-shadow: none;
    padding-inline-start: 0.45rem;
  }

  :deep(.fy-event-chip__icon) {
    color: var(--chip-color, #{$primary});
    flex-shrink: 0;
    font-size: 0.85em;
  }

  // Week view: card-style, fills the time slot.
  :deep(.ec-time-grid .fy-event-chip) {
    flex-direction: column;
    align-items: stretch;
    padding: 0.25rem 0.4rem;
    height: 100%;
    min-height: 1.5rem;
    gap: 0;
  }

  :deep(.fy-event-chip--with-cover) {
    text-shadow: 0 1px 2px rgba(0, 0, 0, 0.9);
    box-shadow: inset 0 0 0 1000px rgba(0, 0, 0, 0.45);
  }

  :deep(.fy-event-chip__time) {
    font-variant-numeric: tabular-nums;
    color: rgba(255, 255, 255, 0.92);
    font-size: 0.78rem;
    flex-shrink: 0;
  }

  // In compact (month) chips the time/title use the page text color, not white.
  :deep(.fy-event-chip--compact .fy-event-chip__time) {
    color: color.adjust($text-color, $lightness: -10%);
  }
  :deep(.fy-event-chip--compact .fy-event-chip__title) {
    color: $text-color;
  }

  :deep(.fy-event-chip__title) {
    font-weight: 600;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    min-width: 0;
  }
}
</style>
