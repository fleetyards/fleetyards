<script lang="ts">
export default {
  name: "FleetLogisticsRouterView",
};
</script>

<script lang="ts" setup>
import {
  FeatureFlagName,
  type Fleet,
  type FleetMember,
} from "@/services/fyApi";
import { useFeatures } from "@/frontend/composables/useFeatures";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const { isFeatureEnabled } = useFeatures();

const resourceAccess = computed(
  () => props.membership?.fleetRole?.resourceAccess,
);
</script>

<template>
  <router-view
    v-if="isFeatureEnabled(FeatureFlagName.fleet_logistics)"
    :fleet="props.fleet"
    :membership="props.membership"
    :resource-access="resourceAccess"
  />
</template>
