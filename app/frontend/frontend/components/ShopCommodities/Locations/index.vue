<template>
  <div>
    <div v-if="item.availability.listedAt && item.availability.listedAt.length">
      <span class="metrics-label">{{ t("availability.listedAt") }}:</span>
      <ul class="list-unstyled">
        <li
          v-for="location in item.availability.listedAt"
          :key="`${item.id}-sell-${location.id}-${location.shop.slug}`"
          class="prices-item"
        >
          <span class="location-item">
            <router-link :to="shopRoute(location.shop)">
              {{ location.shop.name }}
            </router-link>
            {{ location.shop.locationLabel }}
          </span>
        </li>
      </ul>
    </div>
    <div v-if="item.availability.soldAt && item.availability.soldAt.length">
      <span class="metrics-label">{{ t("availability.soldAt") }}:</span>
      <ul class="list-unstyled">
        <li
          v-for="location in item.availability.soldAt"
          :key="`${item.id}-sell-${location.id}-${location.shop.slug}`"
          class="prices-item"
        >
          <span class="location-item">
            <router-link :to="shopRoute(location.shop)">
              {{ location.shop.name }}
            </router-link>
            {{ location.shop.locationLabel }}
          </span>

          <b v-html="toUEC(location.prices.sellPrice)" />
        </li>
      </ul>
    </div>
    <div v-if="item.availability.boughtAt && item.availability.boughtAt.length">
      <span class="metrics-label">{{ t("availability.boughtAt") }}:</span>
      <ul class="list-unstyled">
        <li
          v-for="location in item.availability.boughtAt"
          :key="`${item.id}-buy-${location.id}-${location.shop.slug}`"
          class="prices-item"
        >
          <span class="location-item">
            <router-link :to="shopRoute(location.shop)">
              {{ location.shop.name }}
            </router-link>
            {{ location.shop.locationLabel }}
          </span>
          <b v-html="toUEC(location.prices.buyPrice)" />
        </li>
      </ul>
    </div>
  </div>
</template>

<script lang="ts" setup>
import {
  type Model,
  type Equipment,
  type Commodity,
  type Shop,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  item: Model | Equipment | Commodity;
};

defineProps<Props>();

const { t, toUEC } = useI18n();

const shopRoute = (shop: Shop) => {
  return {
    name: "shop",
    params: {
      stationSlug: shop.station.slug,
      slug: shop.slug,
    },
  };
};
</script>

<script lang="ts">
export default {
  name: "ShopCommodityLocations",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
