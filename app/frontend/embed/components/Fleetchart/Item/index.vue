<template>
  <div
    v-tooltip.bottom="label"
    class="fleetchart-item fade-list-item"
    :class="`model-${model.slug}`"
  >
    <a :href="url" target="_blank" rel="noopener">
      <FleetchartItemImage
        v-if="model.media.fleetchartImage"
        :src="model.media.fleetchartImage"
        :length="length"
        :label="model.name"
        :scale="scale"
      />
    </a>
  </div>
</template>

<script lang="ts" setup>
import FleetchartItemImage from "@/embed/components/Fleetchart/Image/index.vue";
import type { Model } from "@/services/fyApi";

type Props = {
  model: Model;
  scale: number;
};

const props = defineProps<Props>();

const length = computed(() => {
  if (props.model.metrics.fleetchartLength) {
    return props.model.metrics.fleetchartLength;
  }

  return props.model.metrics.length || 0;
});

const url = computed(
  () => `${window.FRONTEND_ENDPOINT}/ships/${props.model.slug}`
);

const label = computed(
  () => `${props.model.manufacturer?.code} ${props.model.name}`
);
</script>

<script lang="ts">
export default {
  name: "FleetchartItem",
};
</script>
