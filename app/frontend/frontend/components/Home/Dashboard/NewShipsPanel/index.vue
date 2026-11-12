<script lang="ts">
export default {
  name: "HomeDashboardNewShipsPanel",
};
</script>

<script lang="ts" setup>
import DashboardPanel from "@/shared/components/Dashboard/Panel/index.vue";
import ShipTile from "@/frontend/components/Home/Dashboard/ShipTile/index.vue";
import { useScDataPatchSummary } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useFullRows } from "@/frontend/components/Home/Dashboard/useFullRows";

const { t } = useI18n();

// The ships the patch of the source being read added to the game, the same
// list the landing page's patch section names.
const { data, isLoading, isFetching, isLoadingError } = useScDataPatchSummary();

const ships = computed(() => data.value?.newShips || []);

const grid = useTemplateRef<HTMLElement>("grid");

const shown = useFullRows(grid, ships, 1);
</script>

<template>
  <!-- A patch that added no ships has nothing to say here. -->
  <DashboardPanel
    v-if="isLoading || isLoadingError || ships.length"
    :title="t('home.dashboard.newShips.title')"
    :pending="isLoading"
    :fetching="isFetching"
    :failed="isLoadingError"
    :empty="!ships.length"
    :more="{ name: 'stats' }"
    :more-label="t('home.dashboard.newShips.all')"
    data-test="home-new-ships"
  >
    <div ref="grid" class="home-new-ships">
      <ShipTile
        v-for="ship in shown"
        :key="ship.id"
        :name="ship.name"
        :sub="ship.manufacturerName"
        :image="ship.storeImage"
        :to="{ name: 'ship', params: { slug: ship.slug } }"
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
