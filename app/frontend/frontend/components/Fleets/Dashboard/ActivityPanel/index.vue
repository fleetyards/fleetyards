<script lang="ts">
export default {
  name: "FleetDashboardActivityPanel",
};
</script>

<script lang="ts" setup>
import DashboardPanel from "@/frontend/components/Fleets/Dashboard/DashboardPanel/index.vue";
import ActivityList from "@/frontend/components/Fleets/Dashboard/ActivityList/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import type { Fleet, FleetActivity } from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  // The dashboard's one activity answer, already narrowed to what no other
  // panel tells.
  entries: FleetActivity[];
  loading?: boolean;
  hasMore?: boolean;
};

withDefaults(defineProps<Props>(), {
  loading: false,
  hasMore: false,
});

defineEmits<{ more: [] }>();

const { t } = useI18n();
</script>

<template>
  <DashboardPanel
    v-if="entries.length"
    :title="t('fleetDashboard.activity.title')"
    :loading="loading"
    data-test="fleet-dashboard-activity"
  >
    <ActivityList :fleet="fleet" :entries="entries" />
    <Btn
      v-if="hasMore"
      class="activity-panel__more"
      :size="BtnSizesEnum.SM"
      @click="$emit('more')"
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
