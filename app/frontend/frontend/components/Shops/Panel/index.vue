<template>
  <Panel
    :id="`${shop.station.slug}-${shop.slug}`"
    class="shop-list"
    :to="detailRoute"
    :link-label="shop.name"
    :bg-image="image"
  >
    <PanelHeading level="h2" size="large" shadow="top">
      <router-link :to="detailRoute" :aria-label="shop.name">
        {{ shop.name }}
      </router-link>
      <template v-if="withLocation" #subtitle>
        {{ shop.station.name }} {{ shop.location }}
      </template>
    </PanelHeading>
  </Panel>
</template>

<script lang="ts" setup>
import Panel from "@/shared/components/Panel/index.vue";
import PanelHeading from "@/shared/components/Panel/Heading/index.vue";
import fallbackImageJpg from "@/images/fallback/store_image.jpg";
import fallbackImage from "@/images/fallback/store_image.webp";
import { useWebpCheck } from "@/shared/composables/useWebpCheck";
import type { Shop } from "@/services/fyApi";

type Props = {
  shop: Shop;
  withLocation?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withLocation: false,
});

const { supported: webpSupported } = useWebpCheck();

const image = computed(() => {
  if (props.shop.media.storeImage) {
    return props.shop.media.storeImage.medium;
  }

  if (webpSupported) {
    return fallbackImage;
  }

  return fallbackImageJpg;
});

const detailRoute = computed(() => {
  return {
    name: "shop",
    params: {
      stationSlug: props.shop.station.slug,
      slug: props.shop.slug,
    },
  };
});
</script>

<script lang="ts">
export default {
  name: "ShopPanel",
};
</script>

<style lang="scss">
@import "index";
</style>
