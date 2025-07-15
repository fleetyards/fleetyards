<script lang="ts">
export default {
  name: "BaseTableCol",
};
</script>

<script lang="ts" setup>
import {
  BaseTableColAlignmentEnum,
  BaseTableHeaderColVariantEnum,
} from "@/shared/components/base/Table/types";

type Props = {
  as?: "td" | "th";
  alignment?: `${BaseTableColAlignmentEnum}`;
  variant?: `${BaseTableHeaderColVariantEnum}`;
};

const props = withDefaults(defineProps<Props>(), {
  as: "td",
  alignment: BaseTableColAlignmentEnum.LEFT,
  variant: BaseTableHeaderColVariantEnum.DEFAULT,
});

const cssClasses = computed(() => {
  return {
    [`base-table-col--${props.alignment}`]:
      props.alignment !== BaseTableColAlignmentEnum.LEFT,
    [`base-table-col--${props.variant}`]:
      props.variant !== BaseTableHeaderColVariantEnum.DEFAULT,
  };
});
</script>

<template>
  <component :is="props.as" class="base-table-col" :class="cssClasses">
    <div class="base-table-col__inner">
      <slot />
    </div>
  </component>
</template>

<style lang="scss" scoped>
@import "index";
</style>
