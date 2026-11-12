<script lang="ts">
export default {
  name: "HomeDashboardShipsPanel",
};
</script>

<script lang="ts" setup>
import DashboardPanel from "@/shared/components/Dashboard/Panel/index.vue";
import DashboardEmpty from "@/shared/components/Dashboard/Empty/index.vue";
import ShipTile from "@/frontend/components/Home/Dashboard/ShipTile/index.vue";
import { useFullRows } from "@/frontend/components/Home/Dashboard/useFullRows";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  type Vehicle,
  useHangar,
  useSyncRsiHangarLastRead,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useVehicleRoute } from "@/frontend/composables/useVehicleRoute";
import {
  SHIPS_LISTED,
  dashboardHangarOptions,
  dashboardHangarParams,
} from "@/frontend/components/Home/Dashboard/hangarParams";
import { usePatchChangedTag } from "@/frontend/components/Home/Dashboard/usePatchChangedTag";

const { t, l } = useI18n();

const toVehicle = useVehicleRoute();

const { data, isLoading, isFetching, isLoadingError } = useHangar(
  dashboardHangarParams,
  dashboardHangarOptions,
);

const vehicles = computed(() => data.value?.items || []);

const hasFlagship = computed(() => !!vehicles.value[0]?.flagship);

// A flagship stands in the header already.
const listed = computed(() =>
  hasFlagship.value
    ? vehicles.value.slice(1)
    : vehicles.value.slice(0, SHIPS_LISTED),
);

const { data: lastRead } = useSyncRsiHangarLastRead({
  query: { retry: false },
});

const tagFor = usePatchChangedTag();

const tagsFor = (vehicle: Vehicle) => {
  const tag = tagFor(vehicle);

  return tag ? [{ label: tag }] : [];
};

// A ship the pilot named shows its model; otherwise its maker.
const subFor = (vehicle: Vehicle) =>
  vehicle.name ? vehicle.model.name : vehicle.model.manufacturer?.name;

const grid = useTemplateRef<HTMLElement>("grid");

const shown = useFullRows(grid, listed, 2);

// Everything neither here nor in the header, rows cut to fit included.
const remaining = computed(() =>
  Math.max(
    (data.value?.meta.pagination?.totalCount || 0) -
      shown.value.length -
      (hasFlagship.value ? 1 : 0),
    0,
  ),
);
</script>

<template>
  <!-- A hangar of only the flagship has said everything in the header. -->
  <DashboardPanel
    v-if="isLoading || isLoadingError || listed.length || !vehicles.length"
    :title="t('home.dashboard.ships.title')"
    :pending="isLoading"
    :fetching="isFetching"
    :failed="isLoadingError"
    :empty="!vehicles.length"
    :more="{ name: 'hangar' }"
    :more-label="t('home.dashboard.ships.open')"
    data-test="home-ships"
  >
    <p v-if="lastRead?.finishedAt" class="home-ships__synced">
      <i class="fa-light fa-arrows-rotate" aria-hidden="true" />
      {{
        t("home.dashboard.ships.synced", {
          time: l(lastRead.finishedAt, "datetime.formats.short"),
        })
      }}
    </p>
    <div ref="grid" class="home-ships">
      <ShipTile
        v-for="vehicle in shown"
        :key="vehicle.id"
        :name="vehicle.name || vehicle.model.name"
        :sub="subFor(vehicle)"
        :image="vehicle.model.media.storeImage"
        :tags="tagsFor(vehicle)"
        :to="toVehicle('hangar-vehicle', vehicle)"
        data-test="home-ships-item"
      />
    </div>
    <p v-if="remaining" class="home-ships__more">
      {{ t("home.dashboard.ships.more", { count: remaining }) }}
    </p>
    <template #empty>
      <DashboardEmpty
        icon="fa-warehouse"
        :title="t('home.dashboard.ships.empty.title')"
        :hint="t('home.dashboard.ships.empty.hint')"
      >
        <Btn :size="BtnSizesEnum.SM" :to="{ name: 'hangar' }">
          {{ t("home.dashboard.ships.empty.action") }}
        </Btn>
      </DashboardEmpty>
    </template>
  </DashboardPanel>
</template>

<style lang="scss" scoped>
.home-ships {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: 12px;
}

.home-ships__synced,
.home-ships__more {
  margin: 0 0 8px;
  color: var(--color-text-dim, #959595);
  font-size: 0.8125rem;
}

.home-ships__more {
  margin: 8px 0 0;
}
</style>
