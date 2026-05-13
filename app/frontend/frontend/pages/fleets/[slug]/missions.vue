<script lang="ts">
export default {
  name: "FleetMissionsRouterView",
};
</script>

<script lang="ts" setup>
import { type Fleet, type FleetMember } from "@/services/fyApi";
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
    v-if="isFeatureEnabled('mission_builder')"
    :fleet="props.fleet"
    :membership="props.membership"
    :resource-access="resourceAccess"
  />
</template>
