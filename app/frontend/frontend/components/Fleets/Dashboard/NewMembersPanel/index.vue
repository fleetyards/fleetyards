<script lang="ts">
export default {
  name: "FleetDashboardNewMembersPanel",
};
</script>

<script lang="ts" setup>
import DashboardPanel from "@/frontend/components/Fleets/Dashboard/DashboardPanel/index.vue";
import ActivityList from "@/frontend/components/Fleets/Dashboard/ActivityList/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  FleetActivityCategoryEnum,
  useFleetActivity,
  type Fleet,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { data, isLoading } = useFleetActivity(
  computed(() => props.fleet.slug),
  { category: FleetActivityCategoryEnum.MEMBERS, limit: 6 },
);

const entries = computed(() => data.value?.items ?? []);
</script>

<template>
  <DashboardPanel
    v-if="entries.length"
    :title="t('fleetDashboard.newMembers.title')"
    :loading="isLoading"
    :more="{ name: 'fleet-members-index', params: { slug: fleet.slug } }"
    data-test="fleet-dashboard-new-members"
  >
    <ActivityList
      :fleet="fleet"
      :entries="entries"
      :show-actor="false"
      :show-kind="false"
    />
  </DashboardPanel>
</template>
