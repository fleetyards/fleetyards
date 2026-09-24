<script lang="ts">
export default {
  name: "FleetSquadronsRouterView",
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
</script>

<template>
  <!-- The feature only: each child route carries its own `access`, and asking
       for read here as well would leave a role that may create squadrons but
       not read them on a blank form. -->
  <router-view
    v-if="isFleetFeatureEnabled(props.fleet, FeatureFlagName.FLEET_SQUADRONS)"
    :fleet="props.fleet"
    :membership="props.membership"
  />
</template>
