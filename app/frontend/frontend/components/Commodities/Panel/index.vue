<template>
  <Panel>
    <div class="teaser-panel">
      <LazyImage
        v-if="commodity.media.storeImage"
        :src="commodity.media.storeImage?.medium"
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

<script lang="ts" setup>
import ShopCommodityLocations from "@/frontend/components/ShopCommodities/Locations/index.vue";
import Panel from "@/shared/components/Panel/index.vue";
import LazyImage from "@/shared/components/LazyImage/index.vue";
import type { Commodity } from "@/services/fyApi";
import { RouteLocationRaw } from "vue-router";

type Props = {
  commodity: Commodity;
  showStats?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  showStats: true,
});

const tradeRouteRoute = computed(() => {
  return {
    name: "trade-routes",
    query: {
      q: {
        commodityIn: [props.commodity.slug],
      },
    },
  } as unknown as RouteLocationRaw; // HACK to make insuffient types for vue-router work
});
</script>

<script lang="ts">
export default {
  name: "ComponentPanel",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
