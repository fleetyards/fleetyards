<script lang="ts">
export default {
  name: "HomeDashboardWishlistPanel",
};
</script>

<script lang="ts" setup>
import DashboardPanel from "@/shared/components/Dashboard/Panel/index.vue";
import DashboardEmpty from "@/shared/components/Dashboard/Empty/index.vue";
import { liveQuery } from "@/shared/components/Dashboard/liveQuery";
import RowListItem from "@/shared/components/RowListItem/index.vue";
import {
  type RowListItemBadge,
  type RowListItemTag,
  RowListItemTonesEnum,
} from "@/shared/components/RowListItem/types";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { type Vehicle, VehicleSortEnum, useWishlist } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import {
  WISHLIST_SHOWN as SHOWN,
  onSaleWishlistParams,
} from "@/frontend/components/Home/Dashboard/wishlistParams";

const { t, toDollar } = useI18n();

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

const tagsFor = (vehicle: Vehicle): RowListItemTag[] =>
  vehicle.model.onSale
    ? [
        {
          key: "on-sale",
          label: t("home.dashboard.wishlist.onSale"),
          tone: RowListItemTonesEnum.PRIMARY,
        },
      ]
    : [];

// The price only says something while the ship can be bought at it.
const badgesFor = (vehicle: Vehicle): RowListItemBadge[] =>
  vehicle.model.onSale && vehicle.model.pledgePrice
    ? [
        {
          key: "price",
          label: t("home.dashboard.wishlist.price"),
          value: toDollar(vehicle.model.pledgePrice),
        },
      ]
    : [];
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
    <div class="home-wishlist">
      <RowListItem
        v-for="vehicle in vehicles"
        :key="vehicle.id"
        :to="{ name: 'ship', params: { slug: vehicle.model.slug } }"
        :tags="tagsFor(vehicle)"
        :badges="badgesFor(vehicle)"
        data-test="home-wishlist-item"
      >
        <template #leading>
          <img
            v-if="vehicle.model.media.storeImage?.smallUrl"
            :src="vehicle.model.media.storeImage.smallUrl"
            alt=""
            class="home-wishlist__image"
            loading="lazy"
          />
        </template>
        <template #name>{{ vehicle.name || vehicle.model.name }}</template>
        <template #sub>
          <span>{{ vehicle.model.manufacturer?.name }}</span>
        </template>
      </RowListItem>
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
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.home-wishlist__image {
  width: 72px;
  height: 44px;
  border-radius: 8px;
  object-fit: cover;
}
</style>
