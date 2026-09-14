<script lang="ts">
export default {
  name: "FleetAlliesRouterView",
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
  <router-view
    v-if="
      isFleetFeatureEnabled(props.fleet, FeatureFlagName.FLEET_ALLIES) &&
      props.membership.capabilities?.readAllies
    "
    :fleet="props.fleet"
    :membership="props.membership"
  />
</template>
