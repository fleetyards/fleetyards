<script lang="ts">
export default {
  name: "ModelCargoMetrics",
};
</script>

<script lang="ts" setup>
import type { Model, CargoHold } from "@/services/fyApi";
import {
  CONTAINER_DEFS,
  SCU_UNIT,
} from "@/frontend/components/CargoGridViewer/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

const { t, toNumber } = useI18n();

type Props = {
  model: Model;
};

const props = defineProps<Props>();

type ContainerCapacity = {
  size: number;
  maxQuantity: number;
};

function computeMaxPerSize(holds: CargoHold[]): ContainerCapacity[] {
  const results: ContainerCapacity[] = [];

  for (const def of CONTAINER_DEFS) {
    let total = 0;

    for (const hold of holds) {
      const maxSize = hold.maxContainerSize?.size || 32;
      if (def.size > maxSize) continue;

      const gridX = hold.dimensions.x / SCU_UNIT;
      const gridY = hold.dimensions.y / SCU_UNIT;
      const gridZ = hold.dimensions.z / SCU_UNIT;

      const orientations = [
        { cx: def.x, cy: def.y, cz: def.z },
        { cx: def.y, cy: def.x, cz: def.z },
      ];

      let best = 0;
      for (const o of orientations) {
        if (o.cx > gridX || o.cy > gridY || o.cz > gridZ) continue;
        const count =
          Math.floor(gridX / o.cx) *
          Math.floor(gridY / o.cy) *
          Math.floor(gridZ / o.cz);
        if (count > best) best = count;
      }

      total += best;
    }

    if (total > 0) {
      results.push({ size: def.size, maxQuantity: total });
    }
  }

  return results;
}

const containerCapacities = computed(() => {
  if (!props.model.cargoHolds?.length) return [];
  return computeMaxPerSize(props.model.cargoHolds);
});

const maxContainerSize = computed(() => {
  if (!props.model.cargoHolds?.length) return null;
  return Math.max(
    ...props.model.cargoHolds.map((h) => h.maxContainerSize?.size || 0),
  );
});
</script>

<template>
  <div
    v-if="containerCapacities.length"
    class="row cargo-metrics metrics-padding"
  >
    <div class="col-12 col-lg-3">
      <div class="metrics-title">
        {{ t("labels.cargoGridViewer.capacity") }}
      </div>
    </div>
    <div class="col-12 col-lg-9 metrics-block">
      <div class="row">
        <div class="col-6 col-lg-4">
          <div class="metrics-label">{{ t("model.cargo") }}:</div>
          <div class="metrics-value">
            {{ toNumber(model.metrics.cargo || "", "cargo") }}
          </div>
        </div>
        <div class="col-6 col-lg-4">
          <div class="metrics-label">
            {{ t("labels.cargoGridViewer.maxContainerSize") }}:
          </div>
          <div class="metrics-value">
            {{ maxContainerSize || "-" }}
            {{ maxContainerSize ? "SCU" : "" }}
          </div>
        </div>
      </div>
      <div class="row">
        <div class="col-12">
          <div class="seperator" />
        </div>
      </div>
      <div class="row">
        <div
          v-for="cap in containerCapacities"
          :key="cap.size"
          class="col-6 col-lg-3"
        >
          <div class="metrics-label">{{ cap.size }} SCU:</div>
          <div class="metrics-value">{{ cap.maxQuantity }}x</div>
        </div>
      </div>
    </div>
  </div>
</template>
