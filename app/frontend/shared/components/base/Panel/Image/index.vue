<script lang="ts">
export default {
  name: "BasePanelImage",
};
</script>

<script lang="ts" setup>
import LazyImage from "@/shared/components/LazyImage/index.vue";
import { RouteLocationRaw } from "vue-router";

type PanelImageRounded = "all" | "top" | "right" | "bottom" | "left";

type Props = {
  image?: string;
  alt?: string;
  to?: RouteLocationRaw;
  rounded?: PanelImageRounded;
  imageSize?: "default" | "auto";
};

withDefaults(defineProps<Props>(), {
  image: undefined,
  alt: "image",
  to: undefined,
  rounded: undefined,
  imageSize: "default",
});
</script>

<template>
  <div
    class="panel-image"
    :class="{
      'panel-image-size-auto': imageSize === 'auto',
      'panel-image-rounded': rounded === 'all',
      'panel-image-rounded-top': rounded === 'top',
      'panel-image-rounded-right': rounded === 'right',
      'panel-image-rounded-bottom': rounded === 'bottom',
      'panel-image-rounded-left': rounded === 'left',
    }"
  >
    <LazyImage v-if="image" :to="to" :aria-label="alt" :src="image" :alt="alt">
      <slot />
    </LazyImage>
  </div>
</template>

<style lang="scss" scoped>
@import "./index.scss";
</style>
