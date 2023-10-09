<template>
  <Panel :id="`${shop.stationSlug}-${shop.slug}`" class="shop-panel">
    <div
      :key="storeImage"
      v-lazy:background-image="storeImage"
      class="panel-bg lazy"
    />
    <div class="row">
      <div class="col-12">
        <div class="panel-heading">
          <h2 class="panel-title">
            <router-link
              :to="{
                name: 'shop',
                params: {
                  stationSlug: shop.station.slug,
                  slug: shop.slug,
                },
              }"
              :aria-label="shop.name"
            >
              <small class="text-muted">
                {{ shop.station.name }} {{ shop.location }}
              </small>
              <br />
              {{ shop.name }}
            </router-link>
          </h2>
        </div>
      </div>
    </div>
  </Panel>
</template>

<script lang="ts" setup>
import Panel from "@/frontend/core/components/Panel/index.vue";
import fallbackImageJpg from "@/images/fallback/store_image.jpg";
import fallbackImage from "@/images/fallback/store_image.webp";
import { useWebpCheck } from "@/frontend/composables/useWebpCheck";

type Props = {
  shop: Shop;
};

const props = defineProps<Props>();

const { supported: webpSupported } = useWebpCheck();

const storeImage = computed(() => {
  if (!props.shop.media.storeImage) {
    if (webpSupported) {
      return fallbackImage;
    }

    return fallbackImageJpg;
  }

  return props.shop.media.storeImage.medium;
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
