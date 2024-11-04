<script lang="ts">
export default {
  name: "BaseHeading",
};
</script>

<script lang="ts" setup>
import {
  HeadingLevelEnum,
  HeadingAlignmentEnum,
} from "@/shared/components/base/Heading/types";

type Props = {
  level?: HeadingLevelEnum;
  hidden?: boolean;
  alignment?: HeadingAlignmentEnum;
};

const props = withDefaults(defineProps<Props>(), {
  level: HeadingLevelEnum.H1,
  hidden: false,
  alignment: HeadingAlignmentEnum.LEFT,
});

const cssClasses = computed(() => {
  return {
    "text-3xl": props.level === "h1",
    "text-2xl": props.level === "h2",
    "text-xl": props.level === "h3",
    "text-lg": props.level === "h4",
    "sr-only": props.hidden,
    "text-center": props.alignment === "center",
    "text-right": props.alignment === "right",
  };
});
</script>

<template>
  <component :is="level" :class="cssClasses">
    <slot />
  </component>
</template>
