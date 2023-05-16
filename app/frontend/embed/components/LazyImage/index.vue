<template>
  <component
    :is="componentType"
    v-if="src"
    :key="src"
    v-lazy:background-image="src"
    v-bind="componentArgs"
    class="lazy-image"
  >
    <slot />
  </component>
</template>

<script lang="ts" setup>
type Props = {
  src: string;
  alt?: string;
  href?: string;
  to?: string;
};

const props = withDefaults(defineProps<Props>(), {
  alt: "image",
  href: undefined,
  to: undefined,
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

const componentArgs = computed(() => {
  if (props.to) {
    return {
      to: props.to,
    };
  }

  if (props.href) {
    return {
      href: props.href,
    };
  }

  return {};
});
</script>

<script lang="ts">
export default {
  name: "LazyImage",
};
</script>
