<script lang="ts">
export default {
  name: "FleetToursRouterView",
};
</script>

<script lang="ts" setup>
import {
  type Fleet,
  type FleetMember,
  FeatureFlagName,
} from "@/services/fyApi";
import { useFeatures } from "@/frontend/composables/useFeatures";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const { isFleetFeatureEnabled } = useFeatures();

const resourceAccess = computed(
  () => props.membership?.fleetRole?.resourceAccess,
);
</script>

<template>
  <router-view
    v-if="
      isFleetFeatureEnabled(props.fleet, FeatureFlagName.TOUR_PAYOUTS) &&
      isFleetFeatureEnabled(props.fleet, FeatureFlagName.FLEET_TOURS)
    "
    :fleet="props.fleet"
    :membership="props.membership"
    :resource-access="resourceAccess"
  />
</template>
