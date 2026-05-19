<script lang="ts">
export default {
  name: "ModelExternalFuelTanks",
};
</script>

<script lang="ts" setup>
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
      });
    }
  }
  return [...map.values()];
});
</script>

<template>
  <div
    v-if="tanks.length"
    class="row external-fuel-tanks metrics-padding"
    data-test="external-fuel-tanks"
  >
    <div class="col-12 col-lg-3">
      <div class="metrics-title">
        {{ t("labels.model.externalFuelTanks") }}
      </div>
    </div>
    <div class="col-12 col-lg-9 metrics-block">
      <div class="row">
        <div class="col-6 col-lg-4">
          <div class="metrics-label">
            {{ t("labels.model.externalFuelTanksTotal") }}:
          </div>
          <div class="metrics-value">
            {{ toNumber(totalCapacity, "cargo") }}
          </div>
        </div>
        <div class="col-6 col-lg-4">
          <div class="metrics-label">
            {{ t("labels.model.externalFuelTanksCount") }}:
          </div>
          <div class="metrics-value">{{ tanks.length }}x</div>
        </div>
      </div>
      <div class="row">
        <div class="col-12">
          <div class="seperator" />
        </div>
      </div>
      <div class="row">
        <div
          v-for="group in groups"
          :key="group.componentName"
          class="col-6 col-lg-4"
        >
          <div class="metrics-label">{{ group.componentName }}:</div>
          <div class="metrics-value">
            {{ group.count }}x &middot;
            {{ toNumber(group.perTankCapacity, "cargo") }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
