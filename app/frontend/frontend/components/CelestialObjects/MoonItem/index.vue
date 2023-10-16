<template>
  <Panel :id="id || moon.slug" class="moon-item">
    <PanelImage class="text-center">
      <router-link
        :key="moon.media?.storeImage?.medium"
        v-lazy:background-image="moon.media?.storeImage?.medium"
        :to="detailRoute"
        :aria-label="moon.name"
        class="lazy"
      />
    </PanelImage>
    <h2 class="panel-title">
      <router-link :to="detailRoute" :aria-label="moon.name">
        {{ moon.name }}
      </router-link>
    </h2>
  </Panel>
</template>

<script lang="ts" setup>
import type { CelestialObject } from "@/services/fyApi";
import Panel from "@/shared/components/Panel/index.vue";
import PanelImage from "@/shared/components/Panel/Image/index.vue";

type Props = {
  moon: CelestialObject;
  id?: string;
};

const props = withDefaults(defineProps<Props>(), {
  id: undefined,
});

const detailRoute = computed(() => {
  return {
    name: "celestial-object",
    params: {
      starsystem: props.moon.starsystem.slug,
      slug: props.moon.slug,
    },
  };
});
</script>

<script lang="ts">
export default {
  name: "CelestialObjectItem",
};
</script>

<style lang="scss">
@import "index";
</style>
