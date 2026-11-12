<script lang="ts">
export default {
  name: "CalendarPage",
};
</script>

<script lang="ts" setup>
import { addDays, endOfMonth, startOfMonth, subDays } from "date-fns";
import Heading from "@/shared/components/base/Heading/index.vue";
import CalendarGrid from "@/frontend/components/Fleets/Events/CalendarGrid/index.vue";
import { type FleetEvent, useMyEvents } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type CalendarView = "month" | "week";

const { t } = useI18n();

const route = useRoute();
const router = useRouter();

const view = computed<CalendarView>(() =>
  route.query.view === "week" ? "week" : "month",
);

const setView = (next: CalendarView) => {
  void router.replace({
    query: { ...route.query, view: next === "month" ? undefined : next },
  });
};

const visibleRange = ref<{ start: Date; end: Date }>({
  start: subDays(startOfMonth(new Date()), 7),
  end: addDays(endOfMonth(new Date()), 7),
});

const params = computed(() => ({
  from: visibleRange.value.start.toISOString(),
  to: visibleRange.value.end.toISOString(),
}));

// Every fleet the pilot is in, merged with the curated in-game events.
const { data, isFetching } = useMyEvents(params);

const entries = computed(() => data.value?.items || []);

// Each fleet event remembers its fleet, so a click opens it in the right one.
const fleetSlugs = computed(() => {
  const map = new Map<FleetEvent, string>();

  entries.value.forEach((entry) => {
    if (entry.fleetEvent && entry.fleet) {
      map.set(entry.fleetEvent, entry.fleet.slug);
    }
  });

  return map;
});

const fleetEvents = computed(() =>
  entries.value.flatMap((entry) =>
    entry.fleetEvent ? [entry.fleetEvent] : [],
  ),
);

const gameEvents = computed(() =>
  entries.value.flatMap((entry) => (entry.gameEvent ? [entry.gameEvent] : [])),
);

const fleetSlugFor = (event: FleetEvent) => fleetSlugs.value.get(event);
</script>

<template>
  <Heading hero>{{ t("headlines.calendar") }}</Heading>

  <CalendarGrid
    :events="fleetEvents"
    :game-events="gameEvents"
    :fleet-slug-for="fleetSlugFor"
    :view="view"
    :loading="isFetching"
    read-only
    data-test="home-calendar"
    @update:range="visibleRange = $event"
    @update:view="setView"
  />
</template>
