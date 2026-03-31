<script lang="ts">
export default {
  name: "HeadingSmall",
};
</script>

<template>
  <small
    class="flex text-[70%] text-brand-textdark font-normal font-opensans gap-2"
  >
    <slot name="default" />
  </small>
</template>

<style lang="scss" scoped>
@import "index";
</style>
