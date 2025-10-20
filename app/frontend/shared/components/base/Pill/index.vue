<script lang="ts">
export default {
  name: "BasePill",
};
</script>

<script lang="ts" setup>
type Props = {
  tag?: "span" | "div" | "p";
  variant?: "default" | "success" | "warning" | "danger";
};

const props = withDefaults(defineProps<Props>(), {
  tag: "span",
  variant: "default",
});

const cssClasses = computed(() => {
  return {
    "base-pill": true,
    "text-white text-base leading-none text-center": true,
    "align-baseline whitespace-nowrap": true,
    "bg-brand-primary": true,
    "rounded px-2.5 py-1.5": true,
    [`base-pill--${props.variant}`]: props.variant !== "default",
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
