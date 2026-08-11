<script lang="ts">
export default {
  name: "ModelExternalFuelTanks",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import type { Model, ExternalFuelTank } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

const { t, toNumber } = useI18n();

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const tanks = computed<ExternalFuelTank[]>(
  () => props.model.externalFuelTanks || [],
);

const totalCapacity = computed(() =>
  tanks.value.reduce((sum, tank) => sum + (tank.capacity || 0), 0),
);

type Group = {
  componentName: string;
  count: number;
  perTankCapacity: number;
  share: number;
};

const groups = computed<Group[]>(() => {
  const map = new Map<string, Group>();

  for (const tank of tanks.value) {
    const key = tank.componentName || "—";
    const existing = map.get(key);

    if (existing) {
      existing.count += 1;
    } else {
      map.set(key, {
        componentName: key,
        count: 1,
        perTankCapacity: tank.capacity || 0,
        share: 0,
      });
    }
  }

  const total = totalCapacity.value;

  return [...map.values()]
    .map((group) => ({
      ...group,
      share: total
        ? Math.round(((group.perTankCapacity * group.count) / total) * 100)
        : 0,
    }))
    .sort((a, b) => b.perTankCapacity * b.count - a.perTankCapacity * a.count);
});
</script>

<template>
  <MetricsCard
    v-if="tanks.length"
    :title="t('labels.model.externalFuelTanks')"
    class="fuel-tanks-panel"
    data-test="external-fuel-tanks"
  >
    <div class="metrics-card__hero">
      <div class="metrics-card__tile metrics-card__tile--primary">
        <div class="metrics-card__tile__label">
          {{ t("labels.model.externalFuelTanksTotal") }}
        </div>
        <div class="metrics-card__tile__value">
          {{ toNumber(totalCapacity, "cargo") }}
        </div>
        <div class="metrics-card__tile__sub">
          {{ t("labels.fuelTanks.capacitySub", { count: tanks.length }) }}
        </div>
      </div>
      <div class="metrics-card__tile">
        <div class="metrics-card__tile__label">
          {{ t("labels.model.externalFuelTanksCount") }}
        </div>
        <div class="metrics-card__tile__value">{{ tanks.length }}x</div>
        <div class="metrics-card__tile__sub">
          {{ t("labels.fuelTanks.podsSub") }}
        </div>
      </div>
    </div>

    <div class="metrics-card__section-label">
      {{ t("labels.fuelTanks.components") }}
    </div>
    <div class="fuel-tanks">
      <div
        v-for="group in groups"
        :key="group.componentName"
        class="fuel-tank"
        :title="group.componentName"
      >
        <div class="fuel-tank__head">
          <span class="fuel-tank__name">{{ group.componentName }}</span>
          <span class="fuel-tank__count">{{ group.count }}x</span>
          <span class="fuel-tank__share">
            {{ toNumber(group.perTankCapacity, "cargo") }}
            {{ t("labels.fuelTanks.perPod") }}
          </span>
        </div>
        <div class="fuel-tank__bar">
          <div
            class="fuel-tank__bar-fill"
            :style="{ width: `${group.share}%` }"
          />
        </div>
      </div>
    </div>

    <div class="metrics-card__footer">
      <span class="metrics-card__hint">{{ t("labels.fuelTanks.hint") }}</span>
    </div>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Models/metricsCard";

.fuel-tanks {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.fuel-tank__head {
  display: flex;
  align-items: baseline;
  gap: 8px;
  margin-bottom: 5px;
}

.fuel-tank__name {
  flex: 1 1 auto;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: 12px;
  color: lighten($text-color, 15%);
}

.fuel-tank__count {
  font-family: "Orbitron", tahoma, sans-serif;
  font-size: 12px;
  font-variant-numeric: tabular-nums;
  color: lighten($text-color, 15%);
}

.fuel-tank__share {
  flex: 0 0 auto;
  font-size: 11px;
  color: $gray;
}

.fuel-tank__bar {
  height: 5px;
  border-radius: 3px;
  background: rgba($gray-light, 0.28);
  overflow: hidden;
}

.fuel-tank__bar-fill {
  height: 100%;
  background: linear-gradient(90deg, $primary, rgba($primary, 0.5));
}
</style>
