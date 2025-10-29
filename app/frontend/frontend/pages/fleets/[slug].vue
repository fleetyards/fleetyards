<script lang="ts">
export default {
  name: "FleetRouterView",
};
</script>

<script lang="ts" setup>
import { useComlink } from "@/shared/composables/useComlink";
import AsyncData from "@/shared/components/AsyncData.vue";
import AccessCheck from "@/shared/components/AccessCheck.vue";
import {
  useFleet as useFleetQuery,
  useFleetMembership as useFleetMembershipQuery,
} from "@/services/fyApi";
import { useFleetMeta } from "@/frontend/composables/useFleetMeta";

const route = useRoute();

const slug = computed(() => route.params.slug as string);

const { data: fleet, refetch, ...asyncFleetStatus } = useFleetQuery(slug);

const { data: membership, ...asyncMembershipStatus } =
  useFleetMembershipQuery(slug);

const comlink = useComlink();

const fleetUpdateComlink = ref();

onMounted(() => {
  fleetUpdateComlink.value = comlink.on("fleet-update", refetch);
});

onUnmounted(() => {
  fleetUpdateComlink.value();
});

useFleetMeta(fleet);
</script>

<template>
  <AsyncData :async-status="asyncFleetStatus">
    <template #resolved>
      <AsyncData :async-status="asyncMembershipStatus">
        <template #resolved>
          <AccessCheck :resource-access="membership?.fleetRole.resourceAccess">
            <template #granted>
              <router-view :fleet="fleet" :membership="membership" />
            </template>
          </AccessCheck>
        </template>
      </AsyncData>
    </template>
  </AsyncData>
</template>
