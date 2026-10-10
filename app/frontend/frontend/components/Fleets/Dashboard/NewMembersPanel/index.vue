<script lang="ts">
export default {
  name: "FleetDashboardNewMembersPanel",
};
</script>

<script lang="ts" setup>
import { liveQuery } from "@/frontend/components/Fleets/Dashboard/liveQuery";
import DashboardPanel from "@/frontend/components/Fleets/Dashboard/DashboardPanel/index.vue";
import DashboardEmpty from "@/frontend/components/Fleets/Dashboard/DashboardEmpty/index.vue";
import ActivityList from "@/frontend/components/Fleets/Dashboard/ActivityList/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  FleetActivityCategoryEnum,
  FleetMembershipSortEnum,
  useFleetActivity,
  type Fleet,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { data, isLoading, isFetching, isLoadingError } = useFleetActivity(
  computed(() => props.fleet.slug),
  { category: FleetActivityCategoryEnum.MEMBERS, limit: 6 },
  { query: liveQuery },
);

const entries = computed(() => data.value?.items ?? []);
</script>

<template>
  <DashboardPanel
    :title="t('fleetDashboard.newMembers.title')"
    :pending="isLoading"
    :fetching="isFetching"
    :failed="isLoadingError"
    :empty="!entries.length"
    :more="{
      name: 'fleet-members-index',
      params: { slug: fleet.slug },
      query: { s: FleetMembershipSortEnum.ACCEPTED_AT_DESC },
    }"
    data-test="fleet-dashboard-new-members"
  >
    <ActivityList
      :fleet="fleet"
      :entries="entries"
      :show-actor="false"
      :show-kind="false"
    />
    <template #empty>
      <DashboardEmpty
        icon="fa-user-plus"
        :title="t('fleetDashboard.newMembers.empty.title')"
        :hint="t('fleetDashboard.newMembers.empty.hint')"
      />
    </template>
  </DashboardPanel>
</template>
