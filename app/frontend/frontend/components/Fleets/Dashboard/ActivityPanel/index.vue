<script lang="ts">
export default {
  name: "FleetDashboardActivityPanel",
};
</script>

<script lang="ts" setup>
import { liveQuery } from "@/frontend/components/Fleets/Dashboard/liveQuery";
import DashboardPanel from "@/frontend/components/Fleets/Dashboard/DashboardPanel/index.vue";
import ActivityList from "@/frontend/components/Fleets/Dashboard/ActivityList/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
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

const PAGE = 15;
const MAX = 50;

// One growing page rather than a cursor: the feed is read from the top, and
// fifty entries back is as far as anybody scrolls a summary.
const limit = ref(PAGE);

const { data, isLoading } = useFleetActivity(
  computed(() => props.fleet.slug),
  computed(() => ({ limit: limit.value, exclude: props.exclude })),
  { query: { ...liveQuery, placeholderData: (previous) => previous } },
);

const entries = computed(() => data.value?.items ?? []);

const canShowMore = computed(
  () => entries.value.length >= limit.value && limit.value < MAX,
);

const showMore = () => {
  limit.value = Math.min(limit.value + PAGE, MAX);
};
</script>

<template>
  <DashboardPanel
    v-if="entries.length"
    :title="t('fleetDashboard.activity.title')"
    :loading="isLoading"
    data-test="fleet-dashboard-activity"
  >
    <ActivityList :fleet="fleet" :entries="entries" />
    <Btn
      v-if="canShowMore"
      class="activity-panel__more"
      :size="BtnSizesEnum.SM"
      @click="showMore"
    >
      {{ t("fleetDashboard.activity.showMore") }}
    </Btn>
  </DashboardPanel>
</template>

<style lang="scss" scoped>
.activity-panel__more {
  margin-top: 16px;
}
</style>
