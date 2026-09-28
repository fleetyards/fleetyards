<script lang="ts">
export default {
  name: "FleetRouterView",
};
</script>

<script lang="ts" setup>
import { useComlink } from "@/shared/composables/useComlink";
import AsyncData from "@/shared/components/AsyncData.vue";
import AccessCheck from "@/shared/components/AccessCheck.vue";
import Loader from "@/shared/components/Loader/index.vue";
import NotAuthorized from "@/shared/components/NotAuthorized/index.vue";
import { ErrorTypesEnum } from "@/shared/components/AsyncData.types";
import { errorTypeFrom } from "@/shared/utils/ErrorTypes";
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

// A signed-in reader falls back to the visitor payload only once the members'
// copy is refused. Racing the two let a member's page render from the visitor
// payload, which leaves out what only members see -- a form seeded from it
// kept the gaps after the members' copy arrived.
const memberFleetRefused = computed(() => !!asyncFleetStatus.error.value);

const { data: publicFleet, ...asyncPublicFleetStatus } = usePublicFleetQuery(
  slug,
  {
    query: {
      enabled: computed(
        () =>
          !!slug.value &&
          (!sessionStore.isAuthenticated || memberFleetRefused.value),
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

// Not isPending: the query is disabled for guests and stays pending forever.
const isMembershipLoading = asyncMembershipStatus.isLoading;

// A 404 only means "not a member"; anything else is a real failure.
const membershipFailed = computed(() => {
  const error = asyncMembershipStatus.error.value;

  return !!error && errorTypeFrom(error) !== ErrorTypesEnum.NOT_FOUND;
});

// Public fleet routes are the ones that don't need a session; every other
// child route reads the membership.
const membershipRequired = computed(
  () => !!route.meta.needsAuthentication && !membership.value,
);

const resolvedFleet = computed(() => fleet.value || publicFleet.value);

const resolvedAsyncFleetStatus = computed(() => {
  if (fleet.value) return asyncFleetStatus;
  if (sessionStore.isAuthenticated && !memberFleetRefused.value) {
    return asyncFleetStatus;
  }
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
      <Loader v-if="isMembershipLoading" :loading="true" />
      <AsyncData
        v-else-if="membershipFailed"
        :async-status="asyncMembershipStatus"
      />
      <NotAuthorized v-else-if="membershipRequired" />
      <AccessCheck
        v-else
        :resource-access="membership?.fleetRole?.resourceAccess"
      >
        <template #granted>
          <router-view :fleet="resolvedFleet" :membership="membership" />
        </template>
      </AccessCheck>
    </template>
  </AsyncData>
</template>
