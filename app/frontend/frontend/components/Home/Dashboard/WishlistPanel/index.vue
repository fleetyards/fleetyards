<script lang="ts">
export default {
  name: "HomeDashboardWishlistPanel",
};
</script>

<script lang="ts" setup>
import DashboardPanel from "@/shared/components/Dashboard/Panel/index.vue";
import DashboardEmpty from "@/shared/components/Dashboard/Empty/index.vue";
import { liveQuery } from "@/shared/components/Dashboard/liveQuery";
import ShipTile from "@/frontend/components/Home/Dashboard/ShipTile/index.vue";
import { useFullRows } from "@/frontend/components/Home/Dashboard/useFullRows";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { type Vehicle, VehicleSortEnum, useWishlist } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import {
  WISHLIST_SHOWN as SHOWN,
  onSaleWishlistParams,
} from "@/frontend/components/Home/Dashboard/wishlistParams";

const { t, toDollar, toUEC } = useI18n();

// A ship on sale is the one thing on a wishlist worth acting on today, so those
// come first, and the rest of the space goes to what was wished for last.
const onSale = useWishlist(onSaleWishlistParams, { query: liveQuery });

const recent = useWishlist(
  { perPage: String(SHOWN), q: { sorts: VehicleSortEnum.CREATED_AT_DESC } },
  { query: liveQuery },
);

const vehicles = computed(() => {
  const saleItems = onSale.data.value?.items || [];
  const saleIds = new Set(saleItems.map((vehicle) => vehicle.id));

  return [
    ...saleItems,
    ...(recent.data.value?.items || []).filter(
      (vehicle) => !saleIds.has(vehicle.id),
    ),
  ].slice(0, SHOWN);
});

const isLoading = computed(
  () => onSale.isLoading.value || recent.isLoading.value,
);

const isFetching = computed(
  () => onSale.isFetching.value || recent.isFetching.value,
);

// Either answer missing makes an empty list a guess, not an empty wishlist.
const isLoadingError = computed(
  () => onSale.isLoadingError.value || recent.isLoadingError.value,
);

// The price only says something while the ship can be bought at it.
const tagFor = (vehicle: Vehicle) => {
  if (!vehicle.model.onSale) return undefined;

  const label = t("home.dashboard.wishlist.onSale");

  return vehicle.model.pledgePrice
    ? `${label} · ${toDollar(vehicle.model.pledgePrice)}`
    : label;
};

// What it costs in the game, where it can be bought there at all.
const subFor = (vehicle: Vehicle) =>
  [
    vehicle.model.manufacturer?.name,
    vehicle.model.price ? toUEC(vehicle.model.price) : undefined,
  ]
    .filter(Boolean)
    .join(" · ");

const grid = useTemplateRef<HTMLElement>("grid");

const shown = useFullRows(grid, vehicles, 2);
</script>

<template>
  <DashboardPanel
    :title="t('home.dashboard.wishlist.title')"
    :pending="isLoading"
    :fetching="isFetching"
    :failed="isLoadingError"
    :empty="!vehicles.length"
    :more="{ name: 'hangar-wishlist' }"
    :more-label="t('home.dashboard.wishlist.all')"
    data-test="home-wishlist"
  >
    <div ref="grid" class="home-wishlist">
      <ShipTile
        v-for="vehicle in shown"
        :key="vehicle.id"
        :name="vehicle.name || vehicle.model.name"
        :sub="subFor(vehicle)"
        :image="vehicle.model.media.storeImage"
        :tag="tagFor(vehicle)"
        :to="{ name: 'ship', params: { slug: vehicle.model.slug } }"
        data-test="home-wishlist-item"
      />
    </div>
    <template #empty>
      <DashboardEmpty
        icon="fa-star"
        :title="t('home.dashboard.wishlist.empty.title')"
        :hint="t('home.dashboard.wishlist.empty.hint')"
      >
        <Btn :size="BtnSizesEnum.SM" :to="{ name: 'ships' }">
          {{ t("home.dashboard.wishlist.empty.action") }}
        </Btn>
      </DashboardEmpty>
    </template>
  </DashboardPanel>
</template>

<style lang="scss" scoped>
.home-wishlist {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: 12px;
}
</style>
