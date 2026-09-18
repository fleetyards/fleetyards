<script lang="ts">
export default {
  name: "FleetEventsPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import GridSkeleton from "@/shared/components/GridSkeleton/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import EmptyInfo from "@/shared/components/Empty/Info/index.vue";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";
import EventPanel from "@/frontend/components/Fleets/Events/EventPanel/index.vue";
import EventsTable from "@/frontend/components/Fleets/Events/EventsTable/index.vue";
import CalendarGrid from "@/frontend/components/Fleets/Events/CalendarGrid/index.vue";
import {
  type Fleet,
  type FleetMember,
  type FleetEvent,
  useFleetEvents,
  useFleetCalendar,
  useFleetCalendarSubscription,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useEventDraft } from "@/frontend/composables/useDraftCreate";
import { useFleetEventListContextStore } from "@/frontend/stores/fleetEventListContext";
import {
  type EventCalendarView,
  type EventTab,
  type EventView,
  DEFAULT_EVENT_VIEW,
  eventTabFrom,
  eventViewFrom,
  isEventCalendarView,
  rememberedTab,
} from "@/frontend/pages/fleets/[slug]/events/views";
import { useEventsStore } from "@/frontend/stores/events";
import { storeToRefs } from "pinia";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { checkAccess } from "@/shared/utils/Access";
import { startOfMonth, endOfMonth, addDays, subDays } from "date-fns";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();

const comlink = useComlink();
const { displaySuccess, displayAlert } = useAppNotifications();
const route = useRoute();
const router = useRouter();

const fleetSlug = computed(() => props.fleet.slug);

const view = computed<EventView>(() => eventViewFrom(route.query.view));

const isCalendar = computed(() => isEventCalendarView(view.value));

const calendarView = computed<EventCalendarView>(() =>
  view.value === "week" ? "week" : "month",
);

const tab = computed<EventTab>(() => eventTabFrom(view.value));

const setView = (next: EventView) => {
  if (view.value === next) return;
  void router.replace({
    name: "fleet-events",
    params: { slug: props.fleet.slug },
    query: {
      ...route.query,
      // The default stays out of the URL, so the page's own address is the
      // short one and only a deliberate choice is spelled out.
      view: next === DEFAULT_EVENT_VIEW ? undefined : next,
      // Drop the legacy calendarView param if it lingers from an older link.
      calendarView: undefined,
    },
  });
};

// Which list tab the calendar came from, so leaving the calendar puts the
// reader back on the tab they left rather than always on "upcoming".
//
// Watches `view` and not `tab`: on a calendar `tab` reports the default, so
// recording it there overwrote the very thing this is for - opening the
// calendar from "archived" and coming back landed on "upcoming".
const lastTab = ref<EventTab>(DEFAULT_EVENT_VIEW);

watch(
  view,
  (current) => {
    lastTab.value = rememberedTab(current, lastTab.value);
  },
  { immediate: true },
);

const toggleListCalendar = (next: "list" | "calendar") => {
  if (next === "list") setView(lastTab.value);
  else setView(view.value === "week" ? "week" : "month");
};

const queryParams = computed(() => ({
  upcoming: tab.value === "upcoming" ? true : undefined,
  past: tab.value === "past" ? true : undefined,
  archived: tab.value === "archived" ? true : undefined,
}));

const {
  data: events,
  refetch: refetchList,
  ...asyncStatus
} = useFleetEvents(fleetSlug, queryParams);

const eventList = computed<FleetEvent[]>(() => events.value?.items ?? []);

const visibleRange = ref<{ start: Date; end: Date }>({
  start: subDays(startOfMonth(new Date()), 7),
  end: addDays(endOfMonth(new Date()), 7),
});

const { create: createEventDraft, pending: creating } = useEventDraft();

/*
 * The button writes the event rather than opening a form that would write it
 * later: an event has to exist before its teams, ships and slots can hang off
 * it, and those are the editor's whole job. Clicking a day on the calendar
 * starts it there rather than now.
 */
const goToCreate = (date: Date) => {
  if (!canCreate.value) return;

  void createEventDraft(props.fleet.slug, { startsAt: date });
};

const calendarParams = computed(() => ({
  from: visibleRange.value.start.toISOString(),
  to: visibleRange.value.end.toISOString(),
}));

const { data: calendarData, refetch: refetchCalendar } = useFleetCalendar(
  fleetSlug,
  calendarParams,
  {
    query: {
      enabled: computed(() => isCalendar.value),
    },
  },
);

const calendarEvents = computed<FleetEvent[]>(
  () => calendarData.value?.items ?? [],
);

const listContext = useFleetEventListContextStore();

watch(
  [view, eventList, calendarEvents],
  ([currentView, list, calendar]) => {
    // The three list tabs are one context to the stepper: whichever of them is
    // showing, the next and previous event are the ones beside it in this list.
    if (!isEventCalendarView(currentView)) {
      listContext.setContext(
        props.fleet.slug,
        "list",
        list.map((event) => event.slug),
      );
    } else {
      listContext.setContext(
        props.fleet.slug,
        currentView === "week" ? "calendar-week" : "calendar-month",
        calendar.map((event) => event.slug),
      );
    }
  },
  { immediate: true },
);

/*
 * `update` as well as `create`, because the button no longer opens a form -- it
 * writes a draft and lands the author in the editor. Somebody who may create but
 * not update would be handed an event they cannot name, publish or throw away.
 */
const canCreate = computed(
  () =>
    checkAccess(props.resourceAccess, [
      "fleet:manage",
      "fleet:events:manage",
      "fleet:events:create",
    ]) &&
    checkAccess(props.resourceAccess, [
      "fleet:manage",
      "fleet:events:manage",
      "fleet:events:update",
    ]),
);

const canManage = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:manage",
    "fleet:events:manage",
    "fleet:events:delete",
  ]),
);

const canManageMissions = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:manage",
    "fleet:missions:manage",
    "fleet:missions:read",
  ]),
);

const { data: subscription } = useFleetCalendarSubscription(fleetSlug);

const canSubscribe = computed(() => subscription.value?.enabled === true);

const canManageCalendar = computed(() =>
  checkAccess(props.resourceAccess, ["fleet:manage", "fleet:events:manage"]),
);

const showCalendarSetupNudge = computed(
  () => canManageCalendar.value && subscription.value?.enabled === false,
);

const subscribe = async () => {
  const url = subscription.value?.feedUrl;
  if (!url) return;
  try {
    await navigator.clipboard.writeText(url);
    displaySuccess({
      text: t("messages.fleet.calendarSubscription.copy.success"),
    });
  } catch {
    displayAlert({
      text: t("messages.fleet.calendarSubscription.copy.failure"),
    });
  }
};

const fleetEventCreatedComlink = ref<() => void>();
const fleetEventUpdatedComlink = ref<() => void>();

onMounted(() => {
  fleetEventCreatedComlink.value = comlink.on("fleet-event-created", () => {
    void refetchList();
    void refetchCalendar();
  });
  fleetEventUpdatedComlink.value = comlink.on("fleet-event-updated", () => {
    void refetchList();
    void refetchCalendar();
  });
});

onUnmounted(() => {
  fleetEventCreatedComlink.value?.();
  fleetEventUpdatedComlink.value?.();
});

const crumbs = computed<Crumb[]>(() => [
  {
    to: { name: "fleet", params: { slug: props.fleet.slug } },
    label: props.fleet.name,
  },
]);

// Cards or dense rows, for the list view only - the calendar is a third shape
// and rides in the route, because a month can be linked to.
const eventsStore = useEventsStore();
const { gridView } = storeToRefs(eventsStore);

const openDisplayOptionsModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/shared/components/DisplayOptionsModal/index.vue"),
    props: {
      gridView: gridView.value,
      testPrefix: "events",
      updateCallback: (next: boolean) => {
        eventsStore.gridView = next;
      },
    },
  });
};
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <Heading size="hero" hero>
    {{ t("headlines.fleets.events.index") }}
  </Heading>

  <Teleport to="#header-right">
    <Btn
      v-if="canManageMissions"
      :size="BtnSizesEnum.MD"
      :to="{ name: 'fleet-missions', params: { slug: props.fleet.slug } }"
      :aria-label="t('actions.fleets.missions.viewMissions')"
      variant="bare"
      mobile-icon-only
    >
      <i class="fa-light fa-flag-checkered" />
      <span>{{ t("actions.fleets.missions.viewMissions") }}</span>
    </Btn>
    <Btn
      v-if="canCreate"
      :size="BtnSizesEnum.MD"
      :loading="creating"
      @click="goToCreate(new Date())"
      :aria-label="t('actions.fleets.events.create')"
      mobile-icon-only
    >
      <i class="fa-light fa-plus" />
      <span>{{ t("actions.fleets.events.create") }}</span>
    </Btn>
  </Teleport>

  <div class="events-toolbar">
    <!-- The leading slot answers "which events", and what that means depends on
         the view: a list narrows by when, a calendar already shows the month and
         offers to hand it to your own calendar instead. -->
    <div class="events-toolbar__lead">
      <BtnGroup v-if="!isCalendar" segmented data-test="events-tab-switch">
        <Btn
          :active="tab === 'upcoming'"
          mobile-icon-only
          data-test="events-tab-upcoming"
          @click="setView('upcoming')"
        >
          <i class="fa-light fa-calendar-clock" />
          {{ t("labels.fleets.events.upcomingTab") }}
        </Btn>
        <Btn
          :active="tab === 'past'"
          mobile-icon-only
          data-test="events-tab-past"
          @click="setView('past')"
        >
          <i class="fa-light fa-clock-rotate-left" />
          {{ t("labels.fleets.events.pastTab") }}
        </Btn>
        <Btn
          :active="tab === 'archived'"
          mobile-icon-only
          data-test="events-tab-archived"
          @click="setView('archived')"
        >
          <i class="fa-light fa-box-archive" />
          {{ t("labels.fleets.events.archivedTab") }}
        </Btn>
      </BtnGroup>
      <Btn
        v-else-if="canSubscribe"
        v-tooltip="t('labels.fleets.events.subscribeHint')"
        variant="bare"
        @click="subscribe"
      >
        <i class="fa-light fa-calendar-arrow-down" />
        {{ t("actions.fleets.events.subscribe") }}
      </Btn>
      <Btn
        v-else-if="showCalendarSetupNudge"
        :to="{ name: 'fleet-settings-calendar', params: { slug: fleet.slug } }"
        variant="bare"
      >
        <i class="fa-light fa-calendar-plus" />
        {{ t("actions.fleets.events.setUpCalendar") }}
      </Btn>
    </div>

    <div class="events-toolbar__views">
      <!-- Which shape the list itself takes. Beside the list/calendar switch
           rather than inside it: a calendar is a third view of the same
           records, and cards-or-rows is a question only the list answers. -->
      <Btn
        v-if="!isCalendar"
        :size="BtnSizesEnum.SM"
        :aria-label="t('actions.models.openTableConfiguration')"
        data-test="events-display-options"
        @click="openDisplayOptionsModal"
      >
        <i class="fa-duotone fa-sliders" />
      </Btn>

      <BtnGroup segmented data-test="events-view-switch">
        <Btn
          :active="!isCalendar"
          mobile-icon-only
          @click="toggleListCalendar('list')"
        >
          <i class="fa-light fa-list" />
          {{ t("labels.fleets.events.listTab") }}
        </Btn>
        <Btn
          :active="isCalendar"
          mobile-icon-only
          @click="toggleListCalendar('calendar')"
        >
          <i class="fa-light fa-calendar" />
          {{ t("labels.fleets.events.calendarTab") }}
        </Btn>
      </BtnGroup>
    </div>
  </div>

  <FilteredList
    v-if="!isCalendar"
    key="fleet-events-index"
    :name="route.name?.toString() || ''"
    :records="eventList"
    :async-status="asyncStatus"
    :hide-empty="!gridView"
    :placeholders="!gridView"
  >
    <!-- Only the grid needs placeholder cards. In table view the slot is gone,
         which hands the wait to `placeholders` above: the table draws its own
         header and a page of placeholder rows out of an empty record set,
         which is closer to what arrives than cards would be. -->
    <template v-if="gridView" #skeleton="{ filterVisible }">
      <GridSkeleton :filter-visible="filterVisible" />
    </template>

    <!-- Only the list view carries one: the calendar draws its month whether or
         not anything falls in it, and a box over an empty grid says nothing the
         grid does not already. -->
    <template #empty>
      <Empty :variant="EmptyVariantsEnum.BOX" data-test="fleet-events-empty">
        <template #headline="{ queryPresent }">
          <span v-if="!queryPresent">
            {{ t(`empty.fleets.events.${tab}`) }}
          </span>
        </template>

        <template #info="{ queryPresent }">
          <EmptyInfo v-if="queryPresent" :query-present="queryPresent" />
          <template v-else>
            <p>{{ t(`empty.fleets.events.info.${tab}`) }}</p>
            <!-- In the info slot rather than `actions`: Empty only renders its
                 footer when a filter or a page sent the reader here, and this
                 box is what a fleet with no events at all sees. -->
            <Btn
              v-if="canCreate && tab === 'upcoming'"
              :to="{ name: 'fleet-event-new', params: { slug: fleet.slug } }"
            >
              <i class="fa-light fa-plus" />
              <span>{{ t("actions.fleets.events.create") }}</span>
            </Btn>
          </template>
        </template>
      </Empty>
    </template>

    <template #default="{ records, emptyVisible }">
      <Grid v-if="gridView" :records="records as FleetEvent[]" primary-key="id">
        <template #default="{ record }">
          <EventPanel :event="record" :fleet="fleet" :can-manage="canManage" />
        </template>
      </Grid>

      <!-- The dense view: every event on one screen, in the app's table. The
           table draws its own empty row inside its frame, so the list's panel
           would be a second one under it - hence `hide-empty` above. -->
      <EventsTable
        v-else
        :fleet="fleet"
        :events="records as FleetEvent[]"
        :async-status="asyncStatus"
        :empty-visible="emptyVisible"
      />
    </template>
  </FilteredList>

  <CalendarGrid
    v-else
    :fleet="fleet"
    :events="calendarEvents"
    :view="calendarView"
    @update:range="visibleRange = $event"
    @update:view="setView"
    @create-event="goToCreate"
  />
</template>

<style lang="scss" scoped>
/* The gap is the spacing. The `:deep(> *) { margin-right: 0 }` that was here
   cancelled a margin Btn no longer ships. */
.events-toolbar {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  margin-bottom: 12px;
}

/* The display options sit beside the view switch rather than in it, so the two
   stay one block when the toolbar wraps. */
.events-toolbar__views {
  display: flex;
  align-items: center;
  gap: 10px;
}

/* Holds the row's height when the view offers nothing to put here, so the view
   switch on the right does not jump as you move between the two. */
.events-toolbar__lead {
  display: flex;
  align-items: center;
  gap: 10px;
  min-height: 1px;
}
</style>
