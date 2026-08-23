<script lang="ts">
export default {
  name: "HardpointBaseItem",
};
</script>

<script lang="ts" setup>
import HardpointItem from "@/frontend/components/Models/Hardpoints/Item/index.vue";
import HardpointComponent from "@/frontend/components/Models/Hardpoints/Component/index.vue";
import HardpointHeadline from "@/frontend/components/Models/Hardpoints/Headline/index.vue";
import HardpointStats from "@/frontend/components/Models/Hardpoints/Stats/index.vue";
import { type Hardpoint, type CargoHold } from "@/services/fyApi";
import type { HardpointStat } from "@/frontend/composables/useHardpointStats";
import { useI18n } from "@/shared/composables/useI18n";
import { humanizeHoldName } from "@/shared/utils/CargoHolds";

type Props = {
  hardpoints: Hardpoint[];
  intended?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  intended: false,
});

const { t, toNumber } = useI18n();

const hardpoint = computed(() => {
  return props.hardpoints[0];
});

const typeData = computed(() => {
  return hardpoint.value.component?.typeData as CargoHold;
});

const count = computed(() => {
  return props.hardpoints.length;
});

const name = computed(() => {
  return (
    hardpoint.value.component?.name || hardpoint.value.component?.scKey || ""
  );
});

const label = computed(() => {
  return humanizeHoldName(name.value);
});

// The max container size reads as a metric, like every other stat on a hardpoint
// row, rather than as a sentence beside the name.
const stats = computed<HardpointStat[]>(() => {
  const maxContainerSize = typeData.value?.maxContainerSize?.size;

  if (!maxContainerSize) {
    return [];
  }

  return [
    {
      label: t("labels.hardpoint.maxContainerSize"),
      value: String(toNumber(maxContainerSize, "cargo")),
    },
  ];
});
</script>

<template>
  <HardpointItem :count="count" :intended="intended">
    <template #default>
      <HardpointComponent class="hardpoint-item__cargo-component">
        <template v-if="hardpoint.component">
          {{ label }}
        </template>
        <template v-else>TBD</template>
      </HardpointComponent>
      <HardpointHeadline
        v-if="typeData?.capacity"
        :value="toNumber(typeData.capacity, 'cargo')"
        :unit="t('labels.cargoGridViewer.capacity')"
      />
      <HardpointStats :stats="stats" />
    </template>
  </HardpointItem>
</template>

<style lang="scss" scoped>
@import "index";
</style>
