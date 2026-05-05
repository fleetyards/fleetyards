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
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
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
const route = useRoute();
const router = useRouter();

const fleetSlug = computed(() => props.fleet.slug);

const view = computed<"list" | "calendar">(() =>
  route.query.view === "calendar" ? "calendar" : "list",
);

const setView = (next: "list" | "calendar") => {
  if (view.value === next) return;
  void router.replace({
    name: "fleet-events",
    params: { slug: props.fleet.slug },
    query: { ...route.query, view: next === "calendar" ? "calendar" : undefined },
  });
};

const tab = ref<"upcoming" | "past">("upcoming");

const queryParams = computed(() => ({
  upcoming: tab.value === "upcoming" ? true : undefined,
  past: tab.value === "past" ? true : undefined,
}));

const {
  data: events,
  refetch: refetchList,
  ...asyncStatus
} = useFleetEvents(fleetSlug, queryParams);

const eventList = computed<FleetEvent[]>(() => events.value?.items ?? []);

const month = ref(new Date());

const calendarParams = computed(() => ({
  from: subDays(startOfMonth(month.value), 7).toISOString(),
  to: addDays(endOfMonth(month.value), 7).toISOString(),
}));

const { data: calendarData, refetch: refetchCalendar } = useFleetCalendar(
  fleetSlug,
  calendarParams,
  {
    query: {
      enabled: computed(() => view.value === "calendar"),
    },
  },
);

const calendarEvents = computed<FleetEvent[]>(
  () => calendarData.value?.items ?? [],
);

const canCreate = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:manage",
    "fleet:events:manage",
    "fleet:events:create",
  ]),
);

const canManageMissions = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:manage",
    "fleet:missions:manage",
    "fleet:missions:read",
  ]),
);

const icsUrl = computed(() => {
  const token = (props.fleet as { calendarFeedToken?: string | null })
    .calendarFeedToken;
  if (!token) return null;
  return `${window.location.origin}/api/v1/fleets/${props.fleet.slug}/events.ics?token=${token}`;
});

const copyIcs = async () => {
  if (!icsUrl.value) return;
  try {
    await navigator.clipboard.writeText(icsUrl.value);
  } catch {
    // ignore
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
    <BtnGroup>
      <Btn
        :active="view === 'list'"
        size="small"
        inline
        @click="setView('list')"
      >
        <i class="fa-light fa-list" />
        {{ t("labels.fleets.events.listTab") }}
      </Btn>
      <Btn
        :active="view === 'calendar'"
        size="small"
        inline
        @click="setView('calendar')"
      >
        <i class="fa-light fa-calendar" />
        {{ t("labels.fleets.events.calendarTab") }}
      </Btn>
    </BtnGroup>
    <Btn v-if="icsUrl" size="small" inline variant="link" @click="copyIcs">
      <i class="fa-light fa-link" />
      {{ t("labels.fleets.events.openInCalendar") }}
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
        <Btn
          :active="tab === 'past'"
          size="small"
          inline
          @click="tab = 'past'"
        >
          {{ t("labels.fleets.events.pastTab") }}
        </Btn>
      </BtnGroup>
    </template>

    <template #default="{ records }">
      <Grid :records="records as FleetEvent[]" primary-key="id">
        <template #default="{ record }">
          <EventPanel :event="record" :fleet="fleet" />
        </template>
      </Grid>
    </template>
  </FilteredList>

  <CalendarGrid
    v-else
    :fleet="fleet"
    :events="calendarEvents"
    :month="month"
    @update:month="month = $event"
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
