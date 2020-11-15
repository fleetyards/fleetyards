<template>
  <div>
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
          <b>
            {{ $toUEC(location.sellPrice) }}
          </b>
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
          <b>
            {{ $toUEC(location.buyPrice) }}
          </b>
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
        station: shop.station.slug,
        slug: shop.slug,
      },
    }
  }
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
