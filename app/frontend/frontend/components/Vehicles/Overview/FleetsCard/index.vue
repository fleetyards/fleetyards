<script lang="ts">
export default {
  name: "VehicleOverviewFleetsCard",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type VehicleFleet } from "@/services/fyApi";

type Props = {
  fleets: VehicleFleet[];
};

defineProps<Props>();

const { t } = useI18n();
</script>

<template>
  <MetricsCard
    :title="t('labels.vehicleOverview.fleets')"
    variant="slim"
    data-test="vehicle-overview-fleets"
  >
    <ul class="overview-card-rows">
      <li v-for="fleet in fleets" :key="fleet.id" class="overview-card-row">
        <router-link :to="{ name: 'fleet', params: { slug: fleet.slug } }">
          {{ fleet.name }}
        </router-link>
        <span class="overview-card-row__aside">{{ fleet.fid }}</span>
      </li>
    </ul>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "../card.scss";
</style>
