<script lang="ts">
export default {
  name: "BaseSpacer",
};
</script>

<script lang="ts" setup>
type Props = {
  large?: boolean;
  slim?: boolean;
  mb?: boolean;
  dark?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  large: false,
  slim: false,
  mb: false,
  dark: false,
});

const cssClasses = computed(() => {
  return {
    "spacer-large": props.large,
    "spacer-dark": props.dark,
    "spacer-slim": props.slim,
    "spacer-mb": props.mb,
  };
});
</script>

<template>
  <hr class="spacer" :class="cssClasses" />
</template>

<style lang="scss" scoped>
@import "index";
</style>
