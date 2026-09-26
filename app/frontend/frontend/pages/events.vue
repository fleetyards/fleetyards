<script lang="ts">
export default {
  name: "EventsRedirectPage",
};
</script>

<script lang="ts" setup>
import Loader from "@/shared/components/Loader/index.vue";
import { FeatureFlagName, useMyFleets } from "@/services/fyApi";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { type RouteLocationRaw } from "vue-router";

// The app shortcut has to be one fixed URL, but events only exist per fleet,
// so this lands on the first fleet that has them.
const router = useRouter();

const { isFleetFeatureEnabled, features } = useFeatures();

const { data: fleets, isSuccess, isError } = useMyFleets();

const target = computed<RouteLocationRaw | undefined>(() => {
  if (isError.value) {
    return { name: "fleet-add" };
  }

  if (!isSuccess.value || !features.value) {
    return undefined;
  }

  const list = fleets.value ?? [];

  if (!list.length) {
    return { name: "fleet-add" };
  }

  const withEvents = list.find((fleet) =>
    isFleetFeatureEnabled(fleet, FeatureFlagName.FLEET_MISSION_BUILDER),
  );

  if (withEvents) {
    return { name: "fleet-events", params: { slug: withEvents.slug } };
  }

  return { name: "fleet", params: { slug: list[0].slug } };
});

watch(
  target,
  (location) => {
    if (location) {
      void router.replace(location);
    }
  },
  { immediate: true },
);
</script>

<template>
  <Loader :loading="true" fixed />
</template>
