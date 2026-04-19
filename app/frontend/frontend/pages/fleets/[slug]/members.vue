<script lang="ts">
export default {
  name: "FleetMembersRouterView",
};
</script>

<script lang="ts" setup>
import { type Fleet, type FleetMember } from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const resourceAccess = computed(
  () => props.membership?.fleetRole?.resourceAccess,
);
</script>

<template>
  <router-view
    :fleet="props.fleet"
    :membership="props.membership"
    :resource-access="resourceAccess"
  />
</template>
