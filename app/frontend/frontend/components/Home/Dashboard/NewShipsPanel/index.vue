<script lang="ts">
export default {
  name: "HomeDashboardNewShipsPanel",
};
</script>

<script lang="ts" setup>
import DashboardPanel from "@/shared/components/Dashboard/Panel/index.vue";
import ShipTile from "@/frontend/components/Home/Dashboard/ShipTile/index.vue";
import { useModelsLatest } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

const SHOWN = 3;

const { data, isLoading, isFetching, isLoadingError } = useModelsLatest();

const models = computed(() => (data.value || []).slice(0, SHOWN));
</script>

<template>
  <DashboardPanel
    :title="t('home.dashboard.newShips.title')"
    :pending="isLoading"
    :fetching="isFetching"
    :failed="isLoadingError"
    :empty="!models.length"
    :more="{ name: 'ships' }"
    :more-label="t('home.dashboard.newShips.all')"
    data-test="home-new-ships"
  >
    <div class="home-new-ships">
      <ShipTile
        v-for="model in models"
        :key="model.id"
        :name="model.name"
        :sub="model.manufacturer?.name"
        :image="model.media.storeImage"
        :to="{ name: 'ship', params: { slug: model.slug } }"
      />
    </div>
  </DashboardPanel>
</template>

<style lang="scss" scoped>
.home-new-ships {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: 12px;
}
</style>
