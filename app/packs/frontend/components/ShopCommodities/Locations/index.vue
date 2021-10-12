<template>
  <div>
    <div v-if="item.listedAt.length">
      <span class="metrics-label">{{ $t('shopCommodity.listedAt') }}:</span>
      <ul class="list-unstyled">
        <li
          v-for="location in item.listedAt"
          :key="`${item.id}-sell-${location.id}-${location.shop.slug}`"
          class="prices-item"
        >
          <router-link :to="shopRoute(location.shop)">
            {{ location.shop.name }} {{ location.shop.locationLabel }}
          </router-link>
        </li>
      </ul>
    </div>
    <div v-if="item.soldAt.length">
      <span class="metrics-label">{{ $t('shopCommodity.soldAt') }}:</span>
      <ul class="list-unstyled">
        <li
          v-for="location in item.soldAt"
          :key="`${item.id}-sell-${location.id}-${location.shop.slug}`"
          class="prices-item"
        >
          <router-link :to="shopRoute(location.shop)">
            {{ location.shop.name }} {{ location.shop.locationLabel }}
          </router-link>
          <b v-html="$toUEC(location.sellPrice)" />
        </li>
      </ul>
    </div>
    <div v-if="item.boughtAt.length">
      <span class="metrics-label">{{ $t('shopCommodity.boughtAt') }}:</span>
      <ul class="list-unstyled">
        <li
          v-for="location in item.boughtAt"
          :key="`${item.id}-buy-${location.id}-${location.shop.slug}`"
          class="prices-item"
        >
          <router-link :to="shopRoute(location.shop)">
            {{ location.shop.name }} {{ location.shop.locationLabel }}
          </router-link>
          <b v-html="$toUEC(location.buyPrice)" />
        </li>
      </ul>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'

@Component<ShopCommodityLocations>({})
export default class ShopCommodityLocations extends Vue {
  @Prop({ required: true }) item!: any

  shopRoute(shop) {
    return {
      name: 'shop',
      params: {
        stationSlug: shop.station.slug,
        slug: shop.slug,
      },
    }
  }
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
