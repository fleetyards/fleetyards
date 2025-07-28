<script lang="ts">
export default {
  name: "BaseTableRow",
};
</script>

<script lang="ts" setup></script>

<template>
  <tr class="base-table-row">
    <slot />
  </tr>
</template>

<style lang="scss" scoped>
@import "index";
</style>
