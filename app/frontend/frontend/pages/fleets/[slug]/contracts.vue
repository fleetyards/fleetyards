<script lang="ts">
export default {
  name: "FleetContractsRouterView",
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

const { isFleetFeatureEnabled } = useFeatures();

// Every privilege-gated control on the pages below reads this. Without it
// `checkAccess(undefined, ...)` is false for all of them, so the board renders
// with no "create" button and a contract with no publish, edit, fulfil or
// cancel -- the feature looks read-only to the people who own it.
const resourceAccess = computed(
  () => props.membership?.fleetRole?.resourceAccess,
);
</script>

<template>
  <router-view
    v-if="isFleetFeatureEnabled(props.fleet, FeatureFlagName.FLEET_CONTRACTS)"
    :fleet="props.fleet"
    :membership="props.membership"
    :resource-access="resourceAccess"
  />
</template>
