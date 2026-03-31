<script lang="ts">
export default {
  name: "BaseTableRow",
};
</script>

<script lang="ts" setup>
type Props = {
  gridColumns?: string;
  empty?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  gridColumns: "",
  empty: false,
});
</script>

<template>
  <div
    class="base-table-row"
    :class="{ 'base-table-row--empty': props.empty }"
    role="row"
    :style="{ gridTemplateColumns: props.gridColumns }"
  >
    <slot />
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
