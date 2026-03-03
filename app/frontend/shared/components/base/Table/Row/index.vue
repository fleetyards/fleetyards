<script lang="ts">
export default {
  name: "BaseTableRow",
};
</script>

<script lang="ts" setup>
type Props = {
  clickable?: boolean;
};

withDefaults(defineProps<Props>(), {
  clickable: false,
});
</script>

<template>
  <tr class="base-table-row" :class="{ clickable }">
    <slot />
  </tr>
</template>

<style lang="scss" scoped>
@import "index";
</style>
