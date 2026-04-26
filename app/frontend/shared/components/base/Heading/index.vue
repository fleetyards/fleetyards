<script lang="ts">
export default {
  name: "BaseHeading",
};
</script>

<script lang="ts" setup>
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import {
  HeadingLevelEnum,
  HeadingSizeEnum,
  HeadingAlignmentEnum,
} from "@/shared/components/base/Heading/types";

type Props = {
  level?: `${HeadingLevelEnum}`;
  size?: `${HeadingSizeEnum}`;
  alignment?: `${HeadingAlignmentEnum}`;
  hero?: boolean;
  hidden?: boolean;
  shadow?: boolean;
  truncate?: boolean;
  mb?: boolean;
  mt?: boolean;
  inlineSubHeading?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  level: HeadingLevelEnum.H1,
  size: HeadingSizeEnum.XXL,
  hero: false,
  alignment: HeadingAlignmentEnum.LEFT,
  hidden: false,
  shadow: false,
  mb: false,
  mt: false,
  inlineSubHeading: false,
});

const cssClasses = computed(() => {
  return {
    "font-hero": props.hero,
    "font-opensans": !props.hero,
    [`text-${props.size}`]: true,
    "sr-only": props.hidden,
    "text-shadow": props.shadow,
    "mb-4": props.mb,
    "mt-4": props.mt,
    "items-start":
      props.alignment === HeadingAlignmentEnum.LEFT && !props.inlineSubHeading,
    "items-center":
      props.alignment === HeadingAlignmentEnum.CENTER &&
      !props.inlineSubHeading,
    "items-end":
      props.alignment === HeadingAlignmentEnum.RIGHT && !props.inlineSubHeading,
    "justify-start":
      props.alignment === HeadingAlignmentEnum.LEFT && props.inlineSubHeading,
    "justify-center":
      props.alignment === HeadingAlignmentEnum.CENTER && props.inlineSubHeading,
    "justify-end":
      props.alignment === HeadingAlignmentEnum.RIGHT && props.inlineSubHeading,
    "flex-row items-baseline": props.inlineSubHeading,
    "flex-col": !props.inlineSubHeading,
  };
});

const slots = defineSlots<{
  default: [];
  subHeading: [];
}>();
</script>

<template>
  <component :is="level" :class="cssClasses" class="font-normal flex gap-2">
    <slot name="default" />
    <HeadingSmall v-if="slots.subHeading">
      <slot name="subHeading" />
    </HeadingSmall>
  </component>
</template>

<style lang="scss" scoped>
@import "index";
</style>
