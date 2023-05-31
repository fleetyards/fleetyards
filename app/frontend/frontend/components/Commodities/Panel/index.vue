<template>
  <Panel>
    <div class="teaser-panel">
      <LazyImage
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
import type { RouteLocationRaw } from "vue-router";
import Panel from "@/frontend/core/components/Panel/index.vue";
import LazyImage from "@/frontend/core/components/LazyImage/index.vue";
import ShopCommodityLocations from "@/frontend/components/ShopCommodities/Locations/index.vue";

type Props = {
  commodity: TComponent;
  showStats?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  showStats: true,
});

const tradeRouteRoute = computed<RouteLocationRaw>(() => {
  return {
    name: "trade-routes",
    query: {
      q: {
        commodityIn: [props.commodity.slug],
      },
    },
  };
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
