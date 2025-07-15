<script lang="ts">
export default {
  name: "BaseTableCell",
};
</script>

<script lang="ts" setup generic="T">
import {
  BaseTableColAlignmentEnum,
  BaseTableHeaderColVariantEnum,
} from "@/shared/components/base/Table2/types";

type Props = {
  alignment?: `${BaseTableColAlignmentEnum}`;
  variant?: `${BaseTableHeaderColVariantEnum}`;
  header?: boolean;
  role?: "cell" | "columnheader";
};

const props = withDefaults(defineProps<Props>(), {
  alignment: BaseTableColAlignmentEnum.LEFT,
  variant: BaseTableHeaderColVariantEnum.DEFAULT,
  header: false,
  role: "cell",
});

const cssClasses = computed(() => {
  return {
    [`base-table-cell--header`]: props.header,
    [`base-table-cell--align-${props.alignment}`]:
      props.alignment !== BaseTableColAlignmentEnum.LEFT,
    [`base-table-cell--${props.variant}`]:
      props.variant !== BaseTableHeaderColVariantEnum.DEFAULT,
  };
});
</script>

<template>
  <div class="base-table-cell" :class="cssClasses" :role="role">
    <div class="base-table-cell-content">
      <slot />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
