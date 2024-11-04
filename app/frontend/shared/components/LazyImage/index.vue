<script lang="ts">
export default {
  name: "LazyImage",
};
</script>

<script lang="ts" setup>
import { v4 as uuidv4 } from "uuid";
import { RouteLocationRaw } from "vue-router";
import { LazyImageVariantsEnum } from "@/shared/components/LazyImage/types";

type Props = {
  src?: string;
  alt?: string;
  href?: string;
  to?: RouteLocationRaw;
  variant?: LazyImageVariantsEnum;
  shadow?: boolean;
  contain?: boolean;
  width?: number;
  height?: number;
};

const props = withDefaults(defineProps<Props>(), {
  src: undefined,
  alt: "image",
  href: undefined,
  to: undefined,
  variant: undefined,
  shadow: false,
  contain: false,
  width: undefined,
  height: undefined,
});

const uuid = ref<string>(uuidv4());

onMounted(() => {
  uuid.value = uuidv4();
});

const componentType = computed(() => {
  if (props.to) {
    return "router-link";
  }
  if (props.href) {
    return "a";
  }
  return "div";
});

const componentProps = computed(() => {
  if (props.to) {
    return {
      to: props.to,
    };
  }

  if (props.href) {
    return {
      href: props.href,
      target: "_blank",
      "data-pswp-src": props.src,
      "data-pswp-width": props.width,
      "data-pswp-height": props.height,
    };
  }

  return {};
});

const cssClasses = computed(() => {
  return {
    [`lazy-image--${props.variant}`]: !!props.variant,
    "lazy-image--shadow": props.shadow,
    "lazy-image--contain": props.contain,
  };
});
</script>

<template>
  <component
    :is="componentType"
    v-if="src"
    :key="`${src}-${uuid}`"
    v-lazy:background-image="src"
    v-bind="componentProps"
    class="lazy-image"
    :class="cssClasses"
  >
    <slot />
  </component>
</template>

<style lang="scss" scoped>
@import "index";
</style>
