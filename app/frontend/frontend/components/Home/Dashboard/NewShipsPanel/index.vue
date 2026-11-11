<script lang="ts">
export default {
  name: "HomeDashboardNewShipsPanel",
};
</script>

<script lang="ts" setup>
import DashboardPanel from "@/shared/components/Dashboard/Panel/index.vue";
import ShipTile from "@/frontend/components/Home/Dashboard/ShipTile/index.vue";
import { ModelSortEnum, useModels } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useFullRows } from "@/frontend/components/Home/Dashboard/useFullRows";

const { t } = useI18n();

// One full row at the widest the panel gets.
const FETCHED = 5;

// By when the ship joined the database. `/models/latest` sorts by the store
// page's last update, which brings back long-known ships whenever RSI edits
// their page.
const { data, isLoading, isFetching, isLoadingError } = useModels({
  perPage: String(FETCHED),
  q: { sorts: ModelSortEnum.CREATED_AT_DESC },
});

const models = computed(() => data.value?.items || []);

const grid = useTemplateRef<HTMLElement>("grid");

const shown = useFullRows(grid, models, 1);
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
    <div ref="grid" class="home-new-ships">
      <ShipTile
        v-for="model in shown"
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
