<script lang="ts">
export default {
  name: "LazyImage",
};
</script>

<script lang="ts" setup>
import { v4 as uuidv4 } from "uuid";
import { RouteLocationRaw } from "vue-router";
import { LazyImageVariantsEnum } from "@/shared/components/LazyImage/types";
import loadingImage from "@/images/loading.svg";
import placeholderImage from "@/images/fallback/store_image.webp";

type Props = {
  src?: string;
  alt?: string;
  href?: string;
  to?: RouteLocationRaw;
  variant?: LazyImageVariantsEnum;
  shadow?: boolean;
  width?: number;
  height?: number;
  caption?: string;
};

const props = withDefaults(defineProps<Props>(), {
  src: undefined,
  alt: "image",
  href: undefined,
  to: undefined,
  variant: undefined,
  shadow: false,
  width: undefined,
  height: undefined,
  caption: undefined,
});

const uuid = ref<string>(uuidv4());

onMounted(() => {
  uuid.value = uuidv4();
});

const componentType = computed(() => {
  if (props.to) {
    return "router-link";
  }
  return "a";
});

const componentProps = computed(() => {
  if (props.to) {
    return {
      to: props.to,
    };
  } else {
    return {
      href: props.href,
      target: "_blank",
      "data-pswp-src": props.href,
      "data-pswp-width": props.width,
      "data-pswp-height": props.height,
      "data-pswp-cropped": true,
    };
  }
});

const cssClasses = computed(() => {
  return {
    [`lazy-image--${props.variant}`]: !!props.variant,
    "lazy-image--shadow": props.shadow,
    "gallery-image": !!props.href,
  };
});

const imageSrc = computed(() => {
  return props.src || placeholderImage;
});
</script>

<template>
  <component
    :is="componentType"
    :key="`${imageSrc}-${uuid}`"
    v-bind="componentProps"
    class="lazy-image"
    :class="cssClasses"
  >
    <img v-lazy="{ src: imageSrc, loading: loadingImage }" :alt="alt" />
    <slot />
    <!-- eslint-disable-next-line vue/no-v-html -->
    <div v-if="caption" class="hidden-caption-content" v-html="caption" />
  </component>
</template>

<style lang="scss" scoped>
@import "index";
</style>
