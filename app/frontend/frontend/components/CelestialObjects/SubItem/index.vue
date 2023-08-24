<template>
  <Panel :id="id || item.slug" class="station-item">
    <PanelImage class="text-center">
      <router-link
        :key="item.media?.storeImage?.medium"
        v-lazy:background-image="item.media?.storeImage?.medium"
        :to="detailRoute"
        :aria-label="item.name"
        class="lazy"
      />
    </PanelImage>
    <h2 class="panel-title">
      <router-link :to="detailRoute" :aria-label="item.name">
        {{ item.name }}
      </router-link>
    </h2>
  </Panel>
</template>

<script lang="ts" setup>
import type { CelestialObject } from "@/services/fyApi";
import Panel from "@/shared/components/Panel/index.vue";
import PanelImage from "@/shared/components/Panel/Image/index.vue";

type Props = {
  item: CelestialObject;
  id?: string;
};

const props = withDefaults(defineProps<Props>(), {
  id: undefined,
});

const detailRoute = computed(() => {
  return {
    name: "celestial-object",
    params: {
      starsystem: props.item.starsystem.slug,
      slug: props.item.slug,
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
