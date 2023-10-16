<template>
  <Panel
    :id="id || shop.slug"
    class="shop-item"
    :bg-image="shop.media.storeImage?.medium"
    :to="detailRoute"
    :link-label="shop.name"
  >
    <div></div>
    <PanelHeading level="h3" size="large" shadow="bottom">
      <router-link :to="detailRoute" :aria-label="shop.name">
        {{ shop.name }}
      </router-link>
    </PanelHeading>
  </Panel>
</template>

<script lang="ts" setup>
import Panel from "@/shared/components/Panel/index.vue";
import PanelHeading from "@/shared/components/Panel/Heading/index.vue";
import type { Shop } from "@/services/fyApi";

type Props = {
  shop: Shop;
  id?: string;
};

const props = withDefaults(defineProps<Props>(), {
  id: undefined,
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
  name: "ShopsItem",
};
</script>
