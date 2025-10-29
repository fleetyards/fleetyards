<script lang="ts">
export default {
  name: "BaseText",
};
</script>

<script lang="ts" setup></script>

<template>
  <p class="text-brand-text mb-4">
    <slot />
  </p>
</template>

<style lang="scss" scoped>
@import "index";
</style>
