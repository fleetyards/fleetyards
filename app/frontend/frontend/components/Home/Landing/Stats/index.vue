<script lang="ts">
export default {
  name: "HomeLandingStats",
};
</script>

<script lang="ts" setup>
import StatsPanel from "@/shared/components/StatsPanel/index.vue";
import { useStats } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

const { data: stats } = useStats();
</script>

<template>
  <div v-if="stats" class="home-landing-stats" data-test="home-landing-stats">
    <StatsPanel
      :label="t('home.landing.stats.ships')"
      icon="fa-duotone fa-rocket"
      :value="stats.shipsCountTotal"
      :outer-spacing="false"
    />
    <StatsPanel
      :label="t('home.landing.stats.vehicles')"
      icon="fa-duotone fa-warehouse"
      :value="stats.vehiclesCount"
      :outer-spacing="false"
    />
    <StatsPanel
      :label="t('home.landing.stats.fleets')"
      icon="fa-duotone fa-users"
      :value="stats.fleetsCount"
      :outer-spacing="false"
    />
    <StatsPanel
      :label="t('home.landing.stats.changed')"
      icon="fa-duotone fa-code-compare"
      :value="stats.patchChangedShipsCount"
      :outer-spacing="false"
    />
  </div>
</template>

<style lang="scss" scoped>
.home-landing-stats {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 16px;
  margin-top: 32px;
}

@media (max-width: 991px) {
  .home-landing-stats {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 575px) {
  .home-landing-stats {
    gap: 8px;
  }
}
</style>
