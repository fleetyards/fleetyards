<script lang="ts">
export default {
  name: "BaseTableRow",
};
</script>

<script lang="ts" setup>
type Props = {
  clickable?: boolean;
  disabled?: boolean;
};

withDefaults(defineProps<Props>(), {
  clickable: false,
  disabled: false,
});
</script>

<template>
  <tr
    class="base-table-row"
    :class="{ clickable, disabled }"
    :aria-disabled="disabled || undefined"
  >
    <slot />
  </tr>
</template>

<style lang="scss" scoped>
@import "index";
</style>
