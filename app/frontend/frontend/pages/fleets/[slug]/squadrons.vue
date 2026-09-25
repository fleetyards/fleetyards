<script lang="ts">
export default {
  name: "FleetSquadronsRouterView",
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

const { isFleetSquadronsEnabled } = useFeatures();
</script>

<template>
  <!-- The feature only: each child route carries its own `access`, and asking
       for read here as well would leave a role that may create squadrons but
       not read them on a blank form. -->
  <router-view
    v-if="isFleetSquadronsEnabled(props.fleet)"
    :fleet="props.fleet"
    :membership="props.membership"
  />
</template>
