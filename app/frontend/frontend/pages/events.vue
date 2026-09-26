<script lang="ts">
export default {
  name: "EventsRedirectPage",
};
</script>

<script lang="ts" setup>
import Loader from "@/shared/components/Loader/index.vue";
import {
  FeatureFlagName,
  fleetMembership,
  useMyFleets,
  type Fleet,
} from "@/services/fyApi";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { eventsRouteFor } from "@/frontend/composables/useFleetNavAccess";

// The app shortcut has to be one fixed URL, but events only exist per fleet,
// so this lands on the first fleet whose events this member may open.
const router = useRouter();

const {
  isFleetFeatureEnabled,
  features,
  isFetched: featuresFetched,
} = useFeatures();

const { data: fleets, isSuccess, isError } = useMyFleets();

// A failed features request still leaves each fleet's own flags to go on.
const ready = computed(
  () => isSuccess.value && (!!features.value || featuresFetched.value),
);

const eventsRouteIn = async (fleet: Fleet) => {
  try {
    const membership = await fleetMembership(fleet.slug);

    return eventsRouteFor(membership?.fleetRole?.resourceAccess);
  } catch {
    return undefined;
  }
};

const redirect = async () => {
  const list = fleets.value ?? [];

  if (!list.length) {
    return router.replace({ name: "fleet-add" });
  }

  const candidates = list.filter((fleet) =>
    isFleetFeatureEnabled(fleet, FeatureFlagName.FLEET_MISSION_BUILDER),
  );

  for (const fleet of candidates) {
    const name = await eventsRouteIn(fleet);

    if (name) {
      return router.replace({ name, params: { slug: fleet.slug } });
    }
  }

  return router.replace({ name: "fleet", params: { slug: list[0].slug } });
};

watch(
  [ready, isError],
  () => {
    if (isError.value) {
      void router.replace({ name: "home" });
    } else if (ready.value) {
      void redirect();
    }
  },
  { immediate: true },
);
</script>

<template>
  <Loader :loading="true" fixed />
</template>
