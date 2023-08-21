<template>
  <Panel
    v-if="location"
    :id="`${item.type}-${location.slug}`"
    class="celestial-object-panel"
  >
    <div class="panel-image text-center">
      <LazyImage
        :to="route"
        :aria-label="location.name"
        :src="storeImage"
        :alt="location.name"
        class="image"
      />
    </div>
    <div class="panel-heading">
      <h2 class="panel-title">
        <router-link :to="route">
          {{ location.name }}
        </router-link>

        <br />

        <small class="text-muted">
          {{ location.locationLabel }}
        </small>
      </h2>
    </div>
  </Panel>
</template>

<script lang="ts" setup>
import Panel from "@/shared/components/Panel/index.vue";
import LazyImage from "@/shared/components/LazyImage/index.vue";
import fallbackImageJpg from "@/images/fallback/store_image.jpg";
import fallbackImage from "@/images/fallback/store_image.webp";
import { useWebpCheck } from "@/shared/composables/useWebpCheck";
import type {
  SearchResult,
  CelestialObject,
  Starsystem,
} from "@/services/fyApi";
import { SearchResultTypeEnum } from "@/services/fyApi";

type Props = {
  item: SearchResult;
};

const props = defineProps<Props>();

const resultItem = computed(() => props.item.item);

const location = computed(
  () => resultItem.value as CelestialObject | Starsystem
);

const { supported: webpSupported } = useWebpCheck();

const storeImage = computed(() => {
  if (resultItem.value.media?.storeImage) {
    return resultItem.value.media?.storeImage?.medium;
  }

  if (webpSupported) {
    return fallbackImage;
  }

  return fallbackImageJpg;
});

const route = computed(() => {
  switch (props.item.type) {
    case SearchResultTypeEnum.CELESTIAL_OBJECT:
      return {
        name: "celestial-object",
        params: {
          starsystem: (resultItem.value as CelestialObject).starsystem.slug,
          slug: (resultItem.value as CelestialObject).slug,
        },
      };
    case SearchResultTypeEnum.STARSYSTEM:
      return {
        name: "starsystem",
        params: { slug: (resultItem.value as Starsystem).slug },
      };
    default:
      return "";
  }
});
</script>

<script lang="ts">
export default {
  name: "CelestalObjectPanel",
};
</script>

<style lang="scss">
@import "index";
</style>
