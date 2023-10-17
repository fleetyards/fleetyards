<template>
  <Panel v-if="item" :id="`${item.type}-${item.id}`" :bg-image="image">
    <PanelHeading level="h2" size="large">
      {{ name }}
    </PanelHeading>
  </Panel>
</template>

<script lang="ts" setup>
import Panel from "@/shared/components/Panel/index.vue";
import PanelHeading from "@/shared/components/Panel/Heading/index.vue";
import { type SearchResult } from "@/services/fyApi";
import fallbackImageJpg from "@/images/fallback/store_image.jpg";
import fallbackImage from "@/images/fallback/store_image.webp";
import { useWebpCheck } from "@/shared/composables/useWebpCheck";

type Props = {
  item: SearchResult;
};

const props = defineProps<Props>();

const name = computed(() => {
  return props.item.item.name;
});

const { supported: webpSupported } = useWebpCheck();

const image = computed(() => {
  if (props.item.item.media.storeImage) {
    return props.item.item.media.storeImage.medium;
  }

  if (webpSupported) {
    return fallbackImage;
  }

  return fallbackImageJpg;
});
</script>

<script lang="ts">
export default {
  name: "SearchPanel",
};
</script>
