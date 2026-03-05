<script lang="ts">
export default {
  name: "BasePill",
};
</script>

<script lang="ts" setup>
type Props = {
  tag?: "span" | "div" | "p";
  variant?: "default" | "success" | "warning" | "danger";
  uppercase?: boolean;
  marginRight?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  tag: "span",
  variant: "default",
  uppercase: false,
  marginRight: false,
});

const cssClasses = computed(() => {
  return {
    "base-pill": true,
    [`base-pill--${props.variant}`]: props.variant !== "default",
    "base-pill--uppercase": props.uppercase,
    "base-pill--margin-right": props.marginRight,
  };
});
</script>

<template>
  <component :is="tag" :class="cssClasses">
    <slot />
  </component>
</template>

<style lang="scss" scoped>
@import "index";
</style>
