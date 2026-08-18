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
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import { PanelHeadingTonesEnum } from "@/shared/components/base/Panel/Heading/types";
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

// Colour comes from the --color-category-* tokens in entrypoints/tailwind.css
// rather than from literals here: the same eight are needed by the event card
// and the category filter, and five of them alias a token the app already has.
const categoryStyles: Record<string, CategoryStyle> = {
  [MissionCategory.other]: {
    icon: "fa-circle-question",
    color: "var(--color-category-other)",
  },
  [MissionCategory.ship_combat]: {
    icon: "fa-rocket",
    color: "var(--color-category-ship-combat)",
  },
  [MissionCategory.ground_combat]: {
    icon: "fa-burst",
    color: "var(--color-category-ground-combat)",
  },
  [MissionCategory.combined_combat]: {
    icon: "fa-crosshairs",
    color: "var(--color-category-combined-combat)",
  },
  [MissionCategory.mining]: {
    icon: "fa-gem",
    color: "var(--color-category-mining)",
  },
  [MissionCategory.salvage]: {
    icon: "fa-recycle",
    color: "var(--color-category-salvage)",
  },
  [MissionCategory.cargo_hauling]: {
    icon: "fa-box",
    color: "var(--color-category-cargo-hauling)",
  },
  [MissionCategory.exploration]: {
    icon: "fa-compass",
    color: "var(--color-category-exploration)",
  },
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
    /*
     * Built to Chip's own metrics rather than out of Chip itself: the library
     * hands us a DOM node, and Chip's styles are scoped, so its class names
     * would carry nothing here. Mounting a Vue component per event to get them
     * is not worth it for a dot, a time and a label.
     *
     * The icon stays, where a chip would show only a colour dot. The label is
     * the event's title, so nothing else names the category - and colour on its
     * own would be the only thing saying which one it is.
     */
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
        const occurrence = (event as { occurrenceDate?: string | null })
          .occurrenceDate;
        const parentSlug = (event as { parentEventSlug?: string | null })
          .parentEventSlug;
        void router.push({
          name: "fleet-event",
          params: {
            slug: props.fleet.slug,
            event: parentSlug || event.slug,
          },
          query: occurrence ? { occurrence } : undefined,
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
  <!--
    No PanelBody. The grid is drawn edge to edge, and PanelBody's 4px/18px/18px
    is not optional any more - `no-padding` was removed with the redesign, so
    keeping it here would have inset the whole calendar. Panel renders its
    default slot directly when it has no background image, which is what the
    grid wants.
  -->
  <Panel class="fy-calendar">
    <PanelHeading :tone="PanelHeadingTonesEnum.METRIC" divider>
      {{ titleLabel }}
      <template #actions>
        <!-- Actions, so a plain group; the view switch beside it is a switch. -->
        <BtnGroup>
          <Btn :aria-label="t('actions.previous')" @click="goPrev">
            <i class="fa-light fa-chevron-left" />
          </Btn>
          <Btn :aria-label="t('actions.next')" @click="goNext">
            <i class="fa-light fa-chevron-right" />
          </Btn>
          <Btn @click="goToday">
            {{ t("actions.today") }}
          </Btn>
        </BtnGroup>
        <BtnGroup segmented data-test="calendar-view-switch">
          <Btn :active="props.view === 'month'" @click="setView('month')">
            {{ t("labels.fleets.events.calendar.month") }}
          </Btn>
          <Btn :active="props.view === 'week'" @click="setView('week')">
            {{ t("labels.fleets.events.calendar.week") }}
          </Btn>
        </BtnGroup>
      </template>
    </PanelHeading>
    <div ref="calendarEl" class="fy-calendar__body ec-dark" />
  </Panel>
</template>

<style lang="scss" scoped>
/*
 * The library is driven through its own custom properties, which is the seam it
 * gives us, and those are fed from the app's tokens rather than from values
 * remixed here. What is left below that is layout the library does not express
 * as a variable at all.
 *
 * Alphas are the system's documented ones: 0.26 is .btn--grouped.active, 0.22 is
 * .chip--included. Picking them out of the design system rather than by eye is
 * what keeps a highlighted day and a selected chip reading as the same strength.
 */
.fy-calendar__body {
  :deep(.ec) {
    --ec-bg-color: transparent;
    --ec-border-color: var(--color-edge-soft, rgb(122 130 136 / 0.28));
    --ec-text-color: var(--color-text, #c8c8c8);
    --ec-today-bg-color: rgb(66 139 202 / 0.26);
    --ec-highlight-color: rgb(66 139 202 / 0.22);
    --ec-event-bg-color: transparent;
    --ec-event-text-color: var(--color-lifted, #eee);

    background: transparent;
    color: var(--color-text, #c8c8c8);
  }

  // headerToolbar: false empties the library's nav but still mounts it, and the
  // nav keeps its margin-block-end: 1em - a band of dead space above the day
  // labels. Our toolbar is the panel head, so the nav has nothing left to do.
  :deep(.ec-toolbar) {
    display: none;
  }

  // The header rule wants to read as a divider rather than as another cell
  // edge, so it takes the stronger edge token.
  :deep(.ec-col-head),
  :deep(.ec-header .ec-sidebar),
  :deep(.ec-header .ec-day-head),
  :deep(.ec-time-grid .ec-all-day) {
    border-bottom: 1px solid var(--color-edge, rgb(122 130 136 / 0.5));
  }

  :deep(.ec-day-grid .ec-day) {
    --ec-day-bg-color: rgb(0 0 0 / 0.18);
    min-block-size: 7em;
    padding: 7px;
    border: 1px solid var(--ec-border-color);
    border-block-start: none;
    border-inline-start: none;

    &.ec-other-month {
      opacity: 0.4;
    }
  }

  // Today is the day number, not the whole cell: a tinted cell competes with
  // the events inside it.
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
    // The radius everything else at this scale uses; 999px was the only pill
    // left in the feature.
    border-radius: var(--radius-control-bare, 6px);
    background-color: var(--ec-today-bg-color);
    color: #fff;
    font-weight: 600;
  }

  :deep(.ec-col-head.ec-today) {
    background-color: var(--ec-highlight-color) !important;
    box-shadow: inset 0 -2px 0 0 var(--color-primary, #428bca);
  }

  // Week view: vertical day separators plus horizontal hour lines. The library
  // draws the hour lines as a gradient mixing --ec-day-bg-color with
  // --ec-border-color; replaced with one explicit gradient so the lines survive
  // however transparent the day background gets.
  :deep(.ec-time-grid .ec-day) {
    --ec-day-bg-color: rgb(0 0 0 / 0.12);
    background-color: var(--ec-day-bg-color);
    background-image: repeating-linear-gradient(
      to bottom,
      transparent 0,
      transparent calc(var(--ec-slot-height) - 1px),
      var(--ec-border-color) calc(var(--ec-slot-height) - 1px),
      var(--ec-border-color) var(--ec-slot-height)
    );
    background-size: 100% var(--ec-slot-height);
    border: 1px solid var(--ec-border-color);
    border-block-start: none;
    border-inline-start: none;
  }

  :deep(.ec-day-grid.ec-month-view .ec-day-head) {
    padding: 2px 6px 12px;
    flex-direction: row;
    justify-content: center;
  }

  // The weekday strip is a row of labels, so it takes the app's label
  // treatment - Orbitron, tracked, uppercase - instead of a second one.
  :deep(.ec-days .ec-day-head) {
    padding: 9px 10px;
    background: rgb(0 0 0 / 0.28);
    border-bottom: 1px solid var(--color-edge-faint, rgb(122 130 136 / 0.16));
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 10px;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    color: var(--color-gray-light, #7a8288);
  }

  :deep(.ec-day-head time),
  :deep(.ec-time) {
    color: var(--color-gray-light, #7a8288);
    font-size: 12px;
    font-variant-numeric: tabular-nums;
  }

  // The library's .ec-event carries its own padding and fill; zeroed so the
  // chip fills the event box and paints its own.
  :deep(.ec-event) {
    padding: 0;
    overflow: hidden;
  }

  :deep(.fy-event-chip) {
    display: flex;
    align-items: center;
    gap: 7px;
    width: 100%;
    padding: 3px 6px;
    border-radius: var(--radius-control-bare, 6px);
    background-size: cover;
    background-position: center;
    background-repeat: no-repeat;
    color: var(--color-text, #c8c8c8);
    font-size: 13px;
    line-height: 1.3;
    overflow: hidden;
    cursor: pointer;
    box-sizing: border-box;
    transition: background-color 150ms ease-in-out;
  }

  // Month view: Chip's own metrics - the leading marker, the 7px gap, the bare
  // radius - with a category rail in place of the tint, so a day with three
  // events reads as three rows rather than three filled blocks.
  :deep(.fy-event-chip--compact) {
    background-image: none !important;
    padding-inline-start: 7px;
    border-inline-start: 3px solid
      var(--chip-color, var(--color-primary, #428bca));
  }

  :deep(.fy-event-chip--compact:hover) {
    background-color: rgb(122 130 136 / 0.16);
    color: var(--color-lifted, #eee);
  }

  :deep(.fy-event-chip__icon) {
    color: var(--chip-color, var(--color-primary, #428bca));
    flex-shrink: 0;
    font-size: 12px;
    width: 12px;
    text-align: center;
  }

  // Week view: the chip fills its time slot and carries the cover behind a
  // scrim, so it is a card rather than a row.
  :deep(.ec-time-grid .fy-event-chip) {
    flex-direction: column;
    align-items: stretch;
    gap: 0;
    padding: 4px 6px;
    height: 100%;
    min-height: 1.5rem;
    background-color: rgb(66 139 202 / 0.85);
    color: #fff;
  }

  :deep(.fy-event-chip--with-cover) {
    text-shadow: 0 1px 2px rgb(0 0 0 / 0.9);
    box-shadow: inset 0 0 0 1000px rgb(0 0 0 / 0.45);
  }

  :deep(.fy-event-chip__time) {
    flex-shrink: 0;
    font-variant-numeric: tabular-nums;
    font-size: 12px;
    color: var(--color-gray-light, #7a8288);
  }

  :deep(.ec-time-grid .fy-event-chip__time) {
    color: rgb(255 255 255 / 0.92);
  }

  :deep(.fy-event-chip__title) {
    min-width: 0;
    font-weight: 600;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  @media (prefers-reduced-motion: reduce) {
    :deep(.fy-event-chip) {
      transition-duration: 1ms;
    }
  }
}
</style>
