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
import { useFleetSubscription } from "@/frontend/composables/useFleetSubscription";
import SubscriptionRequired from "@/shared/components/SubscriptionRequired/index.vue";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const { isFleetFeatureEnabled } = useFeatures();

// Whole-page rather than inside the list: the filters, the toolbar and
// the create button all belong to a feature this fleet does not have, and
// framing them around a refusal reads as a broken page.
const { subscriptionRequired } = useFleetSubscription(() => props.fleet);

// Every privilege-gated control on the pages below reads this. Without it
// `checkAccess(undefined, ...)` is false for all of them, so the board renders
// with no "create" button and a contract with no publish, edit, fulfil or
// cancel -- the feature looks read-only to the people who own it.
const resourceAccess = computed(
  () => props.membership?.fleetRole?.resourceAccess,
);
</script>

<template>
  <template
    v-if="isFleetFeatureEnabled(props.fleet, FeatureFlagName.FLEET_CONTRACTS)"
  >
    <SubscriptionRequired v-if="subscriptionRequired" />
    <router-view
      v-else
      :fleet="props.fleet"
      :membership="props.membership"
      :resource-access="resourceAccess"
    />
  </template>
</template>
