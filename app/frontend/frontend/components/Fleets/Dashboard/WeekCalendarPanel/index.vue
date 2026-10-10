<script lang="ts">
export default {
  name: "FleetDashboardWeekCalendarPanel",
};
</script>

<script lang="ts" setup>
import { liveQuery } from "@/frontend/components/Fleets/Dashboard/liveQuery";
import CalendarGrid from "@/frontend/components/Fleets/Events/CalendarGrid/index.vue";
import WeekStrip from "@/frontend/components/Fleets/Dashboard/WeekStrip/index.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { useI18n } from "@/shared/composables/useI18n";
import { useFleetCalendar, type Fleet } from "@/services/fyApi";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

// A phone gets the week as a strip of days; the grid's seven columns need the
// width of a desk.
const mobile = useMobile();

// Set by the grid once it has drawn its week, so the first frame has no query
// yet and counts as loading.
const visibleRange = ref<{ start: Date; end: Date } | null>(null);

const { data, isFetching, isError, isPlaceholderData } = useFleetCalendar(
  computed(() => props.fleet.slug),
  computed(() =>
    visibleRange.value
      ? {
          from: visibleRange.value.start.toISOString(),
          to: visibleRange.value.end.toISOString(),
        }
      : {},
  ),
  {
    query: {
      ...liveQuery,
      enabled: computed(() => !mobile.value && !!visibleRange.value),
    },
  },
);

const events = computed(() => data.value?.items ?? []);

const { t } = useI18n();

// Paging keeps the last week's answer as a placeholder, so a failed new week
// would otherwise draw as an empty one.
const failed = computed(
  () => isError.value && (!data.value || isPlaceholderData.value),
);
</script>

<template>
  <WeekStrip v-if="mobile" :fleet="fleet" />
  <CalendarGrid
    v-else
    :fleet="fleet"
    :events="events"
    view="week"
    compact
    :loading="isFetching || !visibleRange"
    data-test="fleet-dashboard-calendar"
    @update:range="visibleRange = $event"
  >
    <template v-if="failed" #notice>
      <p
        class="week-calendar__failed"
        data-test="fleet-dashboard-calendar-failed"
      >
        {{ t("fleetDashboard.failed") }}
      </p>
    </template>
  </CalendarGrid>
</template>

<style lang="scss" scoped>
.week-calendar__failed {
  margin: 0;
  padding: 12px 18px;
  color: var(--color-text-dim, #959595);
}
</style>
