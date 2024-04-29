<script lang="ts">
export default {
  name: "BaseHeading",
};
</script>

<script lang="ts" setup>
type Props = {
  level?: "h1" | "h2" | "h3" | "h4";
  hide?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  level: "h1",
  hide: false,
});

const cssClasses = computed(() => {
  return {
    "text-3xl": props.level === "h1",
    "text-2xl": props.level === "h2",
    "text-xl": props.level === "h3",
    "text-lg": props.level === "h4",
    "sr-only": props.hide,
  };
});
</script>

<template>
  <component
    :is="level"
    :class="cssClasses"
    class="font-hero font-medium text-brand-text mb-5"
  >
    <slot />
  </component>
</template>
