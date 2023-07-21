<template>
  <Panel
    v-if="location"
    :id="`${item.resultType}-${location.id}`"
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

type Props = {
  item: SearchResult;
};

const props = defineProps<Props>();

const location = computed(() => props.item as CelestialObject | Starsystem);

const { supported: webpSupported } = useWebpCheck();

const storeImage = computed(() => {
  if (props.item.media.storeImage) {
    return props.item.media.storeImage?.medium;
  }

  if (webpSupported) {
    return fallbackImage;
  }

  return fallbackImageJpg;
});

const route = computed(() => {
  switch (props.item.resultType) {
    case "celestial_object":
      return {
        name: "celestial-object",
        params: {
          starsystem: (props.item as CelestialObject).starsystem.slug,
          slug: props.item.slug,
        },
      };
    case "starsystem":
      return { name: "starsystem", params: { slug: props.item.slug } };
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
