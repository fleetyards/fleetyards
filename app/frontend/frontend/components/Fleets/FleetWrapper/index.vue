<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <slot :fleet="fleet" />
    </template>
  </AsyncData>
</template>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import { useFleetQuery } from "@/frontend/composables/useFleetQuery";
import { useI18n } from "@/frontend/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";

type Props = {
  fleetSlug: string;
  titleKey?: string;
};

const props = withDefaults(defineProps<Props>(), {
  titleKey: undefined,
});

const { fleet, asyncStatus } = useFleetQuery(props.fleetSlug);

const { t } = useI18n();

const { updateMetaInfo } = useMetaInfo(t);

const fleetTitle = computed(() => {
  if (!props.titleKey) {
    return fleet.value?.name;
  }

  return t(props.titleKey, { fleet: fleet.value?.name });
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
  name: "FleetWrapper",
};
</script>
