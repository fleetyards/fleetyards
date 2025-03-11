<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <router-view :fleet="fleet" />
    </template>
  </AsyncData>
</template>

<script lang="ts" setup>
import { useComlink } from "@/shared/composables/useComlink";
import AsyncData from "@/shared/components/AsyncData.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { useFleet as useFleetQuery } from "@/services/fyApi";

const route = useRoute();

const slug = computed(() => route.params.slug as string);

const { data: fleet, refetch, ...asyncStatus } = useFleetQuery(slug);

const { t } = useI18n();

const { updateMetaInfo } = useMetaInfo();

const comlink = useComlink();

onMounted(() => {
  comlink.on("fleet-update", refetch);
});

onUnmounted(() => {
  comlink.off("fleet-update", refetch);
});

const fleetTitle = computed(() => {
  if (!route.meta.title) {
    return fleet.value?.name;
  }

  return t(route.meta.title, { fleet: fleet.value?.name });
});

watch(
  () => fleet.value,
  () => {
    if (!fleet.value) {
      return;
    }

    updateMetaInfo({
      title: fleetTitle.value,
      description: fleet.value.description,
      image: fleet.value.logo,
      type: "article",
    });
  },
);
</script>

<script lang="ts">
export default {
  name: "FleetRouterView",
};
</script>
