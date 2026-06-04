<script lang="ts">
export default {
  name: "BaseText",
};
</script>

<script lang="ts" setup>
type Props = {
  noSpacing?: boolean;
  muted?: boolean;
  as?: "p" | "span" | "div";
};

const props = withDefaults(defineProps<Props>(), {
  noSpacing: false,
  muted: false,
  as: "p",
});

const cssClasses = computed(() => ({
  "base-text--no-spacing": props.noSpacing,
  "base-text--muted": props.muted,
}));
</script>

<template>
  <component :is="as" class="base-text text-brand-text" :class="cssClasses">
    <slot />
  </component>
</template>

<style lang="scss" scoped>
@import "index";
</style>
