<script lang="ts">
export default {
  name: "FleetDashboardNewMembersPanel",
};
</script>

<script lang="ts" setup>
import DashboardPanel from "@/frontend/components/Fleets/Dashboard/DashboardPanel/index.vue";
import ActivityList from "@/frontend/components/Fleets/Dashboard/ActivityList/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import type { Fleet, FleetActivity } from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  // Who joined, from the dashboard's one activity answer.
  entries: FleetActivity[];
  loading?: boolean;
};

withDefaults(defineProps<Props>(), {
  loading: false,
});

const { t } = useI18n();
</script>

<template>
  <DashboardPanel
    v-if="entries.length"
    :title="t('fleetDashboard.newMembers.title')"
    :loading="loading"
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
