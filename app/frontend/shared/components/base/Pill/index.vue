<script lang="ts">
export default {
  name: "BasePill",
};
</script>

<script lang="ts" setup>
import {
  PillTagsEnum,
  PillVariantsEnum,
} from "@/shared/components/base/Pill/types";

type Props = {
  tag?: `${PillTagsEnum}`;
  variant?: `${PillVariantsEnum}`;
  uppercase?: boolean;
  marginRight?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  tag: PillTagsEnum.SPAN,
  variant: PillVariantsEnum.DEFAULT,
  uppercase: false,
  marginRight: false,
});

const cssClasses = computed(() => {
  return {
    "base-pill": true,
    [`base-pill--${props.variant}`]: props.variant !== PillVariantsEnum.DEFAULT,
    "base-pill--uppercase": props.uppercase,
    "base-pill--margin-right": props.marginRight,
  };
});
</script>

<template>
  <component :is="tag" :class="cssClasses" data-test="pill">
    <slot />
  </component>
</template>

<style lang="scss" scoped>
@import "index";
</style>
