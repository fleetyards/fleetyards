<script lang="ts">
export default {
  name: "FleetEventsPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import EventPanel from "@/frontend/components/Fleets/Events/EventPanel/index.vue";
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
import { useFleetEventListContextStore } from "@/frontend/stores/fleetEventListContext";
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

type ViewKind = "list" | "month" | "week";

const view = computed<ViewKind>(() => {
  const q = route.query.view;
  return q === "month" || q === "week" ? q : "list";
});

const isCalendar = computed(
  () => view.value === "month" || view.value === "week",
);

const calendarView = computed<"month" | "week">(() =>
  view.value === "week" ? "week" : "month",
);

const setView = (next: ViewKind) => {
  if (view.value === next) return;
  void router.replace({
    name: "fleet-events",
    params: { slug: props.fleet.slug },
    query: {
      ...route.query,
      view: next === "list" ? undefined : next,
      // Drop the legacy calendarView param if it lingers from an older link.
      calendarView: undefined,
    },
  });
};

const toggleListCalendar = (next: "list" | "calendar") => {
  if (next === "list") setView("list");
  else setView(view.value === "week" ? "week" : "month");
};

const tab = ref<"upcoming" | "past" | "archived">("upcoming");

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

const goToCreate = (date: Date) => {
  if (!canCreate.value) return;
  void router.push({
    name: "fleet-event-new",
    params: { slug: props.fleet.slug },
    query: { startsAt: date.toISOString() },
  });
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
    if (currentView === "list") {
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

const canCreate = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:manage",
    "fleet:events:manage",
    "fleet:events:create",
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

onMounted(() => {
  comlink.on("fleet-event-created", () => {
    void refetchList();
    void refetchCalendar();
  });
  comlink.on("fleet-event-updated", () => {
    void refetchList();
    void refetchCalendar();
  });
});

const crumbs = computed(() => [
  {
    to: { name: "fleet", params: { slug: props.fleet.slug } },
    label: props.fleet.name,
  },
]);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <Heading size="hero" hero>
    {{ t("headlines.fleets.events.index") }}
  </Heading>

  <Teleport to="#header-right">
    <Btn
      v-if="canManageMissions"
      :to="{ name: 'fleet-missions', params: { slug: props.fleet.slug } }"
      size="small"
      inline
      variant="link"
    >
      <i class="fa-light fa-flag-checkered" />
      <span>{{ t("actions.fleets.missions.viewMissions") }}</span>
    </Btn>
    <Btn
      v-if="canCreate"
      :to="{ name: 'fleet-event-new', params: { slug: props.fleet.slug } }"
      size="small"
      inline
    >
      <i class="fa-light fa-plus" />
      <span>{{ t("actions.fleets.events.create") }}</span>
    </Btn>
  </Teleport>

  <div class="events-toolbar">
    <BtnGroup inline>
      <Btn
        :active="view === 'list'"
        size="small"
        inline
        @click="toggleListCalendar('list')"
      >
        <i class="fa-light fa-list" />
        {{ t("labels.fleets.events.listTab") }}
      </Btn>
      <Btn
        :active="isCalendar"
        size="small"
        inline
        @click="toggleListCalendar('calendar')"
      >
        <i class="fa-light fa-calendar" />
        {{ t("labels.fleets.events.calendarTab") }}
      </Btn>
    </BtnGroup>
    <Btn
      v-if="canSubscribe"
      v-tooltip="t('labels.fleets.events.subscribeHint')"
      size="small"
      inline
      variant="link"
      @click="subscribe"
    >
      <i class="fa-light fa-calendar-arrow-down" />
      {{ t("actions.fleets.events.subscribe") }}
    </Btn>
    <Btn
      v-else-if="showCalendarSetupNudge"
      :to="{ name: 'fleet-settings-calendar', params: { slug: fleet.slug } }"
      size="small"
      inline
      variant="link"
    >
      <i class="fa-light fa-calendar-plus" />
      {{ t("actions.fleets.events.setUpCalendar") }}
    </Btn>
  </div>

  <FilteredList
    v-if="view === 'list'"
    key="fleet-events-index"
    :name="route.name?.toString() || ''"
    :records="eventList"
    :async-status="asyncStatus"
    hide-empty
  >
    <template #actions-left>
      <BtnGroup>
        <Btn
          :active="tab === 'upcoming'"
          inline
          size="small"
          @click="tab = 'upcoming'"
        >
          {{ t("labels.fleets.events.upcomingTab") }}
        </Btn>
        <Btn :active="tab === 'past'" size="small" inline @click="tab = 'past'">
          {{ t("labels.fleets.events.pastTab") }}
        </Btn>
        <Btn
          :active="tab === 'archived'"
          size="small"
          inline
          @click="tab = 'archived'"
        >
          {{ t("labels.fleets.events.archivedTab") }}
        </Btn>
      </BtnGroup>
    </template>

    <template #default="{ records }">
      <Grid :records="records as FleetEvent[]" primary-key="id">
        <template #default="{ record }">
          <EventPanel :event="record" :fleet="fleet" :can-manage="canManage" />
        </template>
      </Grid>
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
.events-toolbar {
  display: flex;
  flex-wrap: wrap;
  gap: 0.4rem;
  align-items: center;
  margin-bottom: 0.75rem;
}
</style>
