<script lang="ts">
export default {
  name: "HeadingSmall",
};
</script>

<template>
  <small class="text-[70%] text-brand-textdark font-normal font-opensans">
    <slot name="default" />
  </small>
</template>

<style lang="scss" scoped>
@import "index";
</style>
