<script lang="ts">
export default {
  name: "HangarVehicleOverviewPage",
};
</script>

<script lang="ts" setup>
import LogCard from "@/frontend/components/Vehicles/Overview/LogCard/index.vue";
import CargoCard from "@/frontend/components/Vehicles/Overview/CargoCard/index.vue";
import LoadoutsCard from "@/frontend/components/Vehicles/Overview/LoadoutsCard/index.vue";
import ConfigurationCard from "@/frontend/components/Vehicles/Overview/ConfigurationCard/index.vue";
import PaintsCard from "@/frontend/components/Vehicles/Overview/PaintsCard/index.vue";
import VisibilityCard from "@/frontend/components/Vehicles/Overview/VisibilityCard/index.vue";
import FleetsCard from "@/frontend/components/Vehicles/Overview/FleetsCard/index.vue";
import PlaqueCard from "@/frontend/components/Vehicles/Overview/PlaqueCard/index.vue";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { FeatureFlagName, type Vehicle } from "@/services/fyApi";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const { isFeatureEnabled } = useFeatures();

// The same conditions the context menu offers these pages under.
const inGame = computed(() => !!props.vehicle.model.inGame);

// Loaners and wishlist ships get no plaque.
const plaqueVisible = computed(
  () => !props.vehicle.loaner && !props.vehicle.wanted,
);

const cargoVisible = computed(
  () =>
    inGame.value &&
    !props.vehicle.wanted &&
    isFeatureEnabled(FeatureFlagName.SHIP_INVENTORIES),
);
</script>

<template>
  <div class="vehicle-overview">
    <div class="vehicle-overview__grid">
      <div class="vehicle-overview__main">
        <LogCard :vehicle="vehicle" />
        <div v-if="cargoVisible || inGame" class="vehicle-overview__pair">
          <CargoCard v-if="cargoVisible" :vehicle="vehicle" />
          <LoadoutsCard v-if="inGame" :vehicle="vehicle" />
        </div>
      </div>

      <aside class="vehicle-overview__side">
        <PlaqueCard v-if="plaqueVisible" :vehicle="vehicle" />
        <ConfigurationCard :vehicle="vehicle" />
        <PaintsCard :vehicle="vehicle" />
        <VisibilityCard v-if="!vehicle.loaner" :vehicle="vehicle" />
        <FleetsCard v-if="vehicle.fleets?.length" :fleets="vehicle.fleets" />
      </aside>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.vehicle-overview {
  &__grid {
    display: grid;
    grid-template-columns: minmax(0, 2fr) minmax(0, 1fr);
    gap: 20px;
    align-items: start;

    @media (max-width: $desktop-breakpoint) {
      grid-template-columns: minmax(0, 1fr);
    }
  }

  &__main,
  &__side {
    display: flex;
    flex-direction: column;
    gap: 20px;
    min-width: 0;
  }

  // MetricsCard's slim body sits flush under the heading's divider, which
  // suits a list of tiles but crowds running text. The bottom matches, and the
  // last block's own spacing is dropped so it does not add to it.
  :deep(.metrics-card__body--slim) {
    padding-block: 15px;

    > :last-child {
      margin-bottom: 0;
    }
  }

  // Each card keeps its own height: stretched to its neighbour's, a short one
  // grew an empty band above its link row.
  &__pair {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
    gap: 20px;
    align-items: start;
  }
}
</style>
