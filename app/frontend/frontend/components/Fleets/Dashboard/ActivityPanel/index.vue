<script lang="ts">
export default {
  name: "FleetDashboardActivityPanel",
};
</script>

<script lang="ts" setup>
import { liveQuery } from "@/frontend/components/Fleets/Dashboard/liveQuery";
import DashboardPanel from "@/frontend/components/Fleets/Dashboard/DashboardPanel/index.vue";
import ActivityList from "@/frontend/components/Fleets/Dashboard/ActivityList/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  useFleetActivity,
  type Fleet,
  type FleetActivityCategoryEnum,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  // Categories told elsewhere on the page, such as who joined.
  exclude?: FleetActivityCategoryEnum[];
};

const props = withDefaults(defineProps<Props>(), {
  exclude: () => [],
});

const { t } = useI18n();

// One page and no more: each entry links to what it tells of, and the panels
// beside the feed link to the full lists.
const LIMIT = 15;

const { data, isLoading, isFetching } = useFleetActivity(
  computed(() => props.fleet.slug),
  computed(() => ({ limit: LIMIT, exclude: props.exclude })),
  { query: liveQuery },
);

const entries = computed(() => data.value?.items ?? []);
</script>

<template>
  <DashboardPanel
    v-if="isLoading || entries.length"
    :title="t('fleetDashboard.activity.title')"
    :loading="isFetching"
    data-test="fleet-dashboard-activity"
  >
    <ActivityList :fleet="fleet" :entries="entries" />
  </DashboardPanel>
</template>
