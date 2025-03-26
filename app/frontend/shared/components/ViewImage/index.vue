<script lang="ts">
export default {
  name: "ViewImage",
};
</script>

<script lang="ts" setup>
import LazyImage from "@/shared/components/LazyImage/index.vue";
import { type ViewImage } from "@/services/fyApi";
import fallbackImageJpg from "@/images/fallback/store_image.jpg";
import fallbackImage from "@/images/fallback/store_image.webp";
import { useWebpCheck } from "@/shared/composables/useWebpCheck";
import { RouteLocationRaw } from "vue-router";
import { LazyImageVariantsEnum } from "@/shared/components/LazyImage/types";

type Props = {
  image?: ViewImage;
  size: keyof Omit<ViewImage, "width" | "height">;
  alt: string;
  href?: string;
  to?: RouteLocationRaw;
  variant?: LazyImageVariantsEnum;
  shadow?: boolean;
  caption?: string;
};

const props = defineProps<Props>();

const { supported: webpSupported } = useWebpCheck();

const src = computed(() => {
  if (props.image && props.image[props.size]) {
    return props.image[props.size];
  }

  if (webpSupported.value) {
    return fallbackImage;
  }

  return fallbackImageJpg;
});
</script>

<template>
  <LazyImage
    :src="src"
    :alt="alt"
    :variant="variant"
    :shadow="shadow"
    :width="image?.width"
    :height="image?.height"
    :caption="caption"
    :to="to"
    :href="href"
  >
    <slot />
  </LazyImage>
</template>
