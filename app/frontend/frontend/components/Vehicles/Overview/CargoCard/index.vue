<script lang="ts">
export default {
  name: "VehicleOverviewCargoCard",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type Vehicle,
  InventoryUnitEnum,
  useVehicleInventory,
  useVehicleInventoryStock,
} from "@/services/fyApi";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const TOP_COUNT = 4;

const { t, toNumber } = useI18n();

const vehicleId = computed(() => props.vehicle.id);

const { data: inventory, isLoading } = useVehicleInventory(vehicleId);
const { data: stock } = useVehicleInventoryStock(vehicleId);

// `toNumber` reads an empty hold as "not available"; here it is just empty.
const scu = (value: number) => (value ? String(toNumber(value)) : "0");

const capacity = computed(() => props.vehicle.model.metrics.cargo || 0);

const stowed = computed(() => inventory.value?.totalScu || 0);

const fill = computed(() =>
  capacity.value
    ? Math.min(100, Math.round((stowed.value / capacity.value) * 100))
    : 0,
);

const topStock = computed(() =>
  (stock.value || [])
    .filter(
      (position) =>
        position.unit === InventoryUnitEnum.SCU && position.netQuantity > 0,
    )
    .sort((a, b) => b.netQuantity - a.netQuantity)
    .slice(0, TOP_COUNT),
);

const cargoRoute = computed(() => ({
  name: "hangar-vehicle-cargo",
  params: { id: props.vehicle.serial || props.vehicle.id },
}));
</script>

<template>
  <MetricsCard
    :title="t('nav.hangar.vehicleCargo')"
    :loading="isLoading"
    variant="slim"
    data-test="vehicle-overview-cargo"
  >
    <p class="overview-card-muted">
      {{
        capacity
          ? t("labels.vehicleOverview.cargoFill", {
              stowed: scu(stowed),
              capacity: scu(capacity),
            })
          : t("labels.vehicleOverview.cargoStowed", {
              stowed: scu(stowed),
            })
      }}
    </p>
    <div
      v-if="capacity"
      class="overview-cargo__bar"
      role="meter"
      :aria-valuenow="fill"
      aria-valuemin="0"
      aria-valuemax="100"
      :aria-label="t('labels.vehicleOverview.cargoMeter')"
    >
      <div class="overview-cargo__fill" :style="{ width: `${fill}%` }" />
    </div>

    <ul v-if="topStock.length" class="overview-card-rows">
      <li
        v-for="position in topStock"
        :key="position.id"
        class="overview-card-row"
      >
        <span>{{ position.name }}</span>
        <span class="overview-card-row__aside">
          {{ toNumber(position.netQuantity, "cargo") }}
        </span>
      </li>
    </ul>

    <template #footer>
      <router-link :to="cargoRoute" class="overview-card-footer-link">
        {{ t("actions.hangar.manageCargo") }}
      </router-link>
    </template>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "../card.scss";

.overview-cargo {
  &__bar {
    height: 8px;
    margin-bottom: 12px;
    overflow: hidden;
    border-radius: 999px;
    background: var(--color-gray-black);
  }

  &__fill {
    height: 100%;
    background: var(--color-primary);
  }
}
</style>
