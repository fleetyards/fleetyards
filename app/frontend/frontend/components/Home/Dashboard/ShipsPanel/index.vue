<script lang="ts">
export default {
  name: "HomeDashboardShipsPanel",
};
</script>

<script lang="ts" setup>
import DashboardPanel from "@/shared/components/Dashboard/Panel/index.vue";
import DashboardEmpty from "@/shared/components/Dashboard/Empty/index.vue";
import { liveQuery } from "@/shared/components/Dashboard/liveQuery";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import ShipTile from "@/frontend/components/Home/Dashboard/ShipTile/index.vue";
import {
  type Vehicle,
  VehicleSortEnum,
  useHangar,
  useMyPatchChanges,
  useSyncRsiHangarLastRead,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useVehicleRoute } from "@/frontend/composables/useVehicleRoute";

const { t, l } = useI18n();

const toVehicle = useVehicleRoute();

// Two rows of three on a desktop, three of two on a phone.
const SHOWN = 6;

const { data, isLoading, isFetching, isLoadingError } = useHangar(
  { perPage: String(SHOWN), q: { sorts: VehicleSortEnum.CREATED_AT_DESC } },
  { query: liveQuery },
);

const vehicles = computed(() => data.value?.items || []);

const remaining = computed(() =>
  Math.max((data.value?.meta.pagination?.totalCount || 0) - SHOWN, 0),
);

const { data: lastRead } = useSyncRsiHangarLastRead({
  query: { retry: false },
});

// Most builds leave a pilot's ships alone, so the patch has no panel of its
// own: a ship it did change carries a tag, and otherwise nothing says so.
const { data: patchChanges } = useMyPatchChanges({ query: liveQuery });

const changedModelIds = computed(
  () => new Set(patchChanges.value?.ownedModelIds || []),
);

const tagFor = (vehicle: Vehicle) =>
  patchChanges.value && changedModelIds.value.has(vehicle.model.id)
    ? t("home.dashboard.ships.changedIn", {
        version: patchChanges.value.version,
      })
    : undefined;

const subFor = (vehicle: Vehicle) =>
  [
    vehicle.name ? vehicle.model.name : vehicle.model.manufacturer?.name,
    vehicle.hangarGroups[0]?.name,
  ]
    .filter(Boolean)
    .join(" · ");
</script>

<template>
  <DashboardPanel
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
    <div class="home-ships__grid">
      <ShipTile
        v-for="vehicle in vehicles"
        :key="vehicle.id"
        :name="vehicle.name || vehicle.model.name"
        :sub="subFor(vehicle)"
        :image="vehicle.model.media.storeImage"
        :tag="tagFor(vehicle)"
        :to="toVehicle('hangar-vehicle', vehicle)"
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
.home-ships__grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: 12px;
}

.home-ships__synced,
.home-ships__more {
  margin: 0 0 12px;
  color: var(--color-text-dim, #959595);
  font-size: 0.8125rem;
}

.home-ships__more {
  margin: 12px 0 0;
}
</style>
