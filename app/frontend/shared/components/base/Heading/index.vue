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
} from "@/shared/components/base/Heading/types";

type Props = {
  level?: HeadingLevelEnum;
  size?: HeadingSizeEnum;
  hero?: boolean;
  hidden?: boolean;
  shadow?: boolean;
  truncate?: boolean;
  mb?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  level: HeadingLevelEnum.H1,
  size: HeadingSizeEnum.XXL,
  hero: false,
  hidden: false,
  shadow: false,
  mb: false,
});

const cssClasses = computed(() => {
  return {
    "font-hero": props.hero,
    "font-opensans": !props.hero,
    [`text-${props.size}`]: true,
    "sr-only": props.hidden,
    "text-shadow": props.shadow,
    "mb-4": props.mb,
  };
});

const slots = defineSlots<{
  default: [];
  subHeading: [];
}>();
</script>

<template>
  <component
    :is="level"
    :class="cssClasses"
    class="font-normal flex flex-col justify-between"
  >
    <slot name="default" />
    <HeadingSmall v-if="slots.subHeading">
      <slot name="subHeading" />
    </HeadingSmall>
  </component>
</template>

<style lang="scss" scoped>
@import "index";
</style>
