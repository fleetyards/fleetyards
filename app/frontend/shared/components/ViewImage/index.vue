<script lang="ts">
export default {
  name: "ViewImage",
};
</script>

<script lang="ts" setup>
import LazyImage from "@/shared/components/LazyImage/index.vue";
import { type MediaFile } from "@/services/fyApi";
import fallbackImageJpg from "@/images/fallback/store_image.jpg";
import fallbackImage from "@/images/fallback/store_image.webp";
import { useWebpCheck } from "@/shared/composables/useWebpCheck";
import { RouteLocationRaw } from "vue-router";
import { LazyImageVariantsEnum } from "@/shared/components/LazyImage/types";
import { ViewImageSizeEnum, viewImageSizeMapping } from "./types";

type Props = {
  alt: string;
  image?: MediaFile;
  size?: `${ViewImageSizeEnum}`;
  href?: string;
  to?: RouteLocationRaw;
  variant?: LazyImageVariantsEnum;
  shadow?: boolean;
  caption?: string;
  transparent?: boolean;
  withoutFallback?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  image: undefined,
  size: ViewImageSizeEnum.SOURCE,
  href: undefined,
  to: undefined,
  variant: LazyImageVariantsEnum.SMALL,
  shadow: false,
  caption: undefined,
  transparent: false,
  withoutFallback: false,
});

const { supported: webpSupported } = useWebpCheck();

const urlAttr = computed(() => {
  return viewImageSizeMapping[props.size];
});

const src = computed(() => {
  if (props.image && props.image[urlAttr.value]) {
    return props.image[urlAttr.value];
  }

  if (props.withoutFallback) {
    return undefined;
  }

  if (webpSupported.value) {
    return fallbackImage;
  }

  return fallbackImageJpg;
});
</script>

<template>
  <LazyImage
    v-if="src"
    :src="src"
    :alt="alt"
    :variant="variant"
    :shadow="shadow"
    :width="image?.width"
    :height="image?.height"
    :caption="caption"
    :to="to"
    :href="href"
    :transparent="transparent"
  >
    <slot />
  </LazyImage>
</template>
