<script lang="ts">
export default {
  name: "BaseHeading",
};
</script>

<script lang="ts" setup>
import { routeLocationKey } from "vue-router";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import BetaBadge from "@/shared/components/BetaBadge/index.vue";
import { PAGE_FEATURE, isBetaFeature } from "@/shared/utils/BetaFeatures";
import type { FeatureFlagName } from "@/services/fyApi";
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
  // Left to a screen reader on a phone, for a list page whose header and
  // toolbar already say where the reader is.
  mobileHidden?: boolean;
  shadow?: boolean;
  truncate?: boolean;
  mb?: boolean;
  mt?: boolean;
  inlineSubHeading?: boolean;
  // For a page whose route does not carry its flag in `meta.feature`, because
  // a wrapper component gates it instead.
  feature?: FeatureFlagName | FeatureFlagName[];
};

const props = withDefaults(defineProps<Props>(), {
  level: HeadingLevelEnum.H1,
  size: HeadingSizeEnum.XXL,
  hero: false,
  alignment: HeadingAlignmentEnum.LEFT,
  hidden: false,
  mobileHidden: false,
  shadow: false,
  mb: false,
  mt: false,
  inlineSubHeading: false,
  feature: undefined,
});

const cssClasses = computed(() => {
  return {
    "font-hero": props.hero,
    "font-opensans": !props.hero,
    [`text-${props.size}`]: true,
    "sr-only": props.hidden,
    "heading--mobile-hidden": props.mobileHidden,
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

// Injected rather than useRoute() so a heading rendered without a router, in a
// spec or a modal mounted on its own, stays quiet instead of warning.
const route = inject(routeLocationKey, null);

const pageFeature = inject(PAGE_FEATURE, undefined);

// A page behind a beta flag says so next to its title. Only the page's own
// hero h1 carries it, never a section heading further down.
const betaFeature = computed(() => {
  if (!props.hero || props.hidden || props.level !== HeadingLevelEnum.H1) {
    return undefined;
  }

  const feature = props.feature ?? pageFeature ?? route?.meta.feature;

  return isBetaFeature(feature) ? feature : undefined;
});

const slots = defineSlots<{
  default?: () => unknown;
  subHeading?: () => unknown;
}>();
</script>

<template>
  <component :is="level" :class="cssClasses" class="font-normal flex gap-2">
    <span v-if="betaFeature" class="heading__beta">
      <slot name="default" />
      <BetaBadge :feature="betaFeature" />
    </span>
    <slot v-else name="default" />
    <HeadingSmall v-if="slots.subHeading">
      <slot name="subHeading" />
    </HeadingSmall>
  </component>
</template>

<style lang="scss" scoped>
@import "index";

.heading__beta {
  display: inline-flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.75rem;
}
</style>
