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
  usePublicFleet as usePublicFleetQuery,
  useFleetMembership as useFleetMembershipQuery,
} from "@/services/fyApi";
import { useFleetMeta } from "@/frontend/composables/useFleetMeta";
import { useSessionStore } from "@/frontend/stores/session";

const route = useRoute();

const sessionStore = useSessionStore();

const slug = computed(() => route.params.slug as string);

const {
  data: fleet,
  refetch,
  ...asyncFleetStatus
} = useFleetQuery(slug, {
  query: {
    enabled: computed(() => !!slug.value && sessionStore.isAuthenticated),
    retry: false,
  },
});

const { data: publicFleet, ...asyncPublicFleetStatus } = usePublicFleetQuery(
  slug,
  {
    query: {
      enabled: computed(
        () => !!slug.value && (!sessionStore.isAuthenticated || !fleet.value),
      ),
      retry: false,
    },
  },
);

const { data: membership, ...asyncMembershipStatus } = useFleetMembershipQuery(
  slug,
  {
    query: {
      enabled: computed(() => !!slug.value && sessionStore.isAuthenticated),
      retry: false,
    },
  },
);

const resolvedFleet = computed(() => fleet.value || publicFleet.value);

const resolvedAsyncFleetStatus = computed(() => {
  if (fleet.value) return asyncFleetStatus;
  if (publicFleet.value) return asyncPublicFleetStatus;
  if (sessionStore.isAuthenticated) return asyncFleetStatus;
  return asyncPublicFleetStatus;
});

const comlink = useComlink();

const fleetUpdateComlink = ref();

onMounted(() => {
  fleetUpdateComlink.value = comlink.on("fleet-update", refetch);
});

onUnmounted(() => {
  fleetUpdateComlink.value();
});

useFleetMeta(resolvedFleet);
</script>

<template>
  <AsyncData :async-status="resolvedAsyncFleetStatus">
    <template #resolved>
      <AsyncData :async-status="asyncMembershipStatus" :hide-error="true">
        <template #resolved>
          <AccessCheck :resource-access="membership?.fleetRole.resourceAccess">
            <template #granted>
              <router-view :fleet="resolvedFleet" :membership="membership" />
            </template>
          </AccessCheck>
        </template>
      </AsyncData>
    </template>
  </AsyncData>
</template>
