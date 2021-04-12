<template>
  <Panel>
    <div class="teaser-panel">
      <LazyImage
        :src="commodity.storeImageMedium"
        :to="tradeRouteRoute"
        class="teaser-panel-image"
      />
      <div class="teaser-panel-body">
        <h2 v-tooltip="commodity.name">
          <router-link :to="tradeRouteRoute">
            {{ commodity.name }}
            <small v-if="commodity.typeLabel">
              <br />
              {{ commodity.typeLabel }}
            </small>
          </router-link>
        </h2>
        <ShopCommodityLocations :item="commodity" />
      </div>
    </div>
  </Panel>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import Panel from 'frontend/core/components/Panel'
import LazyImage from 'frontend/core/components/LazyImage'
import ShopCommodityLocations from 'frontend/components/ShopCommodities/Locations'

@Component<ComponentPanel>({
  components: {
    Panel,
    LazyImage,
    ShopCommodityLocations,
  },
})
export default class ComponentPanel extends Vue {
  @Prop({ required: true }) commodity!: Component

  @Prop({ default: true }) showStats!: boolean

  get tradeRouteRoute() {
    return {
      name: 'trade-routes',
      query: {
        q: {
          commodityIn: [this.commodity.slug],
        },
      },
    }
  }
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
