<template>
  <Panel
    v-if="celestialObject"
    :id="celestialObject.id"
    class="celestial-object-panel"
  >
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
                name: 'celestial-object',
                params: {
                  slug: celestialObject.slug,
                },
              }"
              :aria-label="celestialObject.name"
            >
              {{ celestialObject.name }}
              <small class="text-muted">
                {{ celestialObject.locationLabel }}
              </small>
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
  celestialObject: CelestialObject;
};

const props = defineProps<Props>();

const { supported: webpSupported } = useWebpCheck();

const storeImage = computed(() => {
  if (props.celestialObject.media.storeImage) {
    return props.celestialObject.media.storeImage?.medium;
  }

  if (webpSupported) {
    return fallbackImage;
  }

  return fallbackImageJpg;
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
