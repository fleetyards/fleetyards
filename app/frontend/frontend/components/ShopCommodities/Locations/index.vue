<template>
  <div>
    <div v-if="item.listedAt && item.listedAt.length">
      <span class="metrics-label">{{ $t("shopCommodity.listedAt") }}:</span>
      <ul class="list-unstyled">
        <li
          v-for="location in item.listedAt"
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
    <div v-if="item.soldAt && item.soldAt.length">
      <span class="metrics-label">{{ $t("shopCommodity.soldAt") }}:</span>
      <ul class="list-unstyled">
        <li
          v-for="location in item.soldAt"
          :key="`${item.id}-sell-${location.id}-${location.shop.slug}`"
          class="prices-item"
        >
          <span class="location-item">
            <router-link :to="shopRoute(location.shop)">
              {{ location.shop.name }}
            </router-link>
            {{ location.shop.locationLabel }}
          </span>

          <b v-html="$toUEC(location.sellPrice)" />
        </li>
      </ul>
    </div>
    <div v-if="item.boughtAt && item.boughtAt.length">
      <span class="metrics-label">{{ $t("shopCommodity.boughtAt") }}:</span>
      <ul class="list-unstyled">
        <li
          v-for="location in item.boughtAt"
          :key="`${item.id}-buy-${location.id}-${location.shop.slug}`"
          class="prices-item"
        >
          <span class="location-item">
            <router-link :to="shopRoute(location.shop)">
              {{ location.shop.name }}
            </router-link>
            {{ location.shop.locationLabel }}
          </span>
          <b v-html="$toUEC(location.buyPrice)" />
        </li>
      </ul>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from "vue";
import { Component, Prop } from "vue-property-decorator";

@Component<ShopCommodityLocations>({})
export default class ShopCommodityLocations extends Vue {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  @Prop({ required: true }) item!: any;

  shopRoute(shop) {
    return {
      name: "shop",
      params: {
        stationSlug: shop.station.slug,
        slug: shop.slug,
      },
    };
  }
}
</script>

<style lang="scss" scoped>
@import "index";
</style>
