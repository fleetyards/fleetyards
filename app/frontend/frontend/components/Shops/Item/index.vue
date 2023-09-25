<template>
  <Panel :id="id || item.slug" class="station-item">
    <PanelImage class="text-center">
      <router-link
        :key="item.media.storeImage?.medium"
        v-lazy:background-image="item.media.storeImage?.medium"
        :to="route"
        :aria-label="item.name"
        class="lazy"
      />
    </PanelImage>
    <h2 class="panel-title">
      <router-link :to="route" :aria-label="item.name">
        {{ item.name }}
      </router-link>
    </h2>
  </Panel>
</template>

<script lang="ts" setup>
import Panel from "@/shared/components/Panel/index.vue";
import PanelImage from "@/shared/components/Panel/Image/index.vue";
import type { RouteLocationRaw } from "vue-router";
import type { Shop } from "@/services/fyApi";

type Props = {
  item: Shop;
  route: RouteLocationRaw;
  id?: string;
};

withDefaults(defineProps<Props>(), {
  id: undefined,
});
</script>

<script lang="ts">
export default {
  name: "ShopsItem",
};
</script>

<style lang="scss">
@import "index";
</style>
