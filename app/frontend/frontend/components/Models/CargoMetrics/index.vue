<script lang="ts">
export default {
  name: "ModelCargoMetrics",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import type { Model, CargoHold } from "@/services/fyApi";
import {
  CONTAINER_DEFS,
  SCU_UNIT,
} from "@/frontend/components/CargoGridViewer/constants";
import { useI18n } from "@/shared/composables/useI18n";

const { t, toNumber } = useI18n();

type Props = {
  model: Model;
  cargoHolds?: CargoHold[];
};

const props = defineProps<Props>();

const holds = computed(() => props.cargoHolds || props.model.cargoHolds || []);

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

const totalCargo = computed(() => {
  return holds.value.reduce((sum, h) => sum + (h.capacity || 0), 0);
});

const containerCapacities = computed(() => {
  if (!holds.value.length) return [];

  const total = totalCargo.value || props.model.metrics.cargo || 0;

  return computeMaxPerSize(holds.value).map((capacity) => {
    const scu = capacity.size * capacity.maxQuantity;

    return {
      ...capacity,
      scu,
      // Boxes of one size rarely tile the grid perfectly, so this is the share
      // of the hold that size can actually fill.
      share: total ? Math.min(100, Math.round((scu / total) * 100)) : 0,
    };
  });
});

const maxContainerSize = computed(() => {
  if (!holds.value.length) return null;
  return Math.max(...holds.value.map((h) => h.maxContainerSize?.size || 0));
});

const hasData = computed(() => containerCapacities.value.length > 0);
</script>

<template>
  <MetricsCard
    v-if="hasData"
    :title="t('labels.cargo.title')"
    class="cargo-panel"
  >
    <div class="metrics-card__hero">
      <div class="metrics-card__tile metrics-card__tile--primary">
        <div class="metrics-card__tile__label">{{ t("model.cargo") }}</div>
        <div class="metrics-card__tile__value">
          {{ toNumber(totalCargo || model.metrics.cargo || "", "integer") }}
          <span class="metrics-card__tile__unit">SCU</span>
        </div>
        <div class="metrics-card__tile__sub">
          {{ t("labels.cargo.holdsSub", { count: holds.length }) }}
        </div>
      </div>
      <div class="metrics-card__tile">
        <div class="metrics-card__tile__label">
          {{ t("labels.cargoGridViewer.maxContainerSize") }}
        </div>
        <div class="metrics-card__tile__value">
          {{ maxContainerSize || "-" }}
          <span v-if="maxContainerSize" class="metrics-card__tile__unit">
            SCU
          </span>
        </div>
        <div class="metrics-card__tile__sub">
          {{ t("labels.cargo.maxContainerSub") }}
        </div>
      </div>
    </div>

    <div class="metrics-card__section-label">
      {{ t("labels.cargo.containers") }}
    </div>
    <div class="cargo-caps">
      <div v-for="cap in containerCapacities" :key="cap.size" class="cargo-cap">
        <div class="cargo-cap__head">
          <span class="cargo-cap__label">{{ cap.size }} SCU</span>
          <span class="cargo-cap__value">{{ cap.maxQuantity }}x</span>
          <span class="cargo-cap__share">
            {{ toNumber(cap.scu, "integer") }} SCU · {{ cap.share }}%
          </span>
        </div>
        <div class="cargo-cap__bar">
          <div
            class="cargo-cap__bar-fill"
            :style="{ width: `${cap.share}%` }"
          />
        </div>
      </div>
    </div>

    <div class="metrics-card__footer">
      <span class="metrics-card__hint">{{ t("labels.cargo.hint") }}</span>
    </div>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";

.cargo-caps {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.cargo-cap {
  display: flex;
  flex-direction: column;
  gap: 5px;

  &__head {
    display: flex;
    align-items: baseline;
    gap: 8px;
  }

  &__label {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 9px;
    letter-spacing: 0.1em;
    text-transform: uppercase;
    color: $gray-light;
    min-width: 52px;
  }

  &__value {
    font-size: 13px;
    font-weight: 600;
    color: $text-color;
    font-variant-numeric: tabular-nums;
  }

  &__share {
    margin-left: auto;
    font-size: 11px;
    color: $gray;
    font-variant-numeric: tabular-nums;
    white-space: nowrap;
  }

  &__bar {
    height: 6px;
    border-radius: 3px;
    background: rgba($gray-light, 0.16);
    overflow: hidden;
  }

  &__bar-fill {
    height: 100%;
    border-radius: 3px;
    background: linear-gradient(90deg, rgba($primary, 0.55), $primary);
    transition: width 0.3s ease;
  }
}
</style>
