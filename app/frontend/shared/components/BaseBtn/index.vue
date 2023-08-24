<template>
  <component
    :is="btnType"
    class="panel-btn"
    :class="cssClasses"
    :disabled="disabled || loading || undefined"
    v-bind="btnProps"
  >
    <BtnInner :loading="loading" :spinner="spinner">
      <slot />
    </BtnInner>
  </component>
</template>

<script lang="ts" setup>
import BtnInner from "@/shared/components/BaseBtn/Inner/index.vue";
import type { SpinnerAlignment } from "@/shared/components/SmallLoader/index.vue";
import { RouteLocationRaw } from "vue-router";

export type BtnVariants =
  | "default"
  | "transparent"
  | "link"
  | "danger"
  | "dropdown";
export type BtnSizes = "default" | "xsmall" | "small" | "large";

export type Props = {
  to?: RouteLocationRaw;
  href?: string;
  type?: "button" | "submit";
  loading?: boolean;
  spinner?: boolean | SpinnerAlignment;
  variant?: BtnVariants;
  size?: BtnSizes;
  exact?: boolean;
  block?: boolean;
  mobileBlock?: boolean;
  inline?: boolean;
  textInline?: boolean;
  active?: boolean;
  disabled?: boolean;
  routeActiveClass?: string;
  inGroup?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  to: undefined,
  href: undefined,
  type: "button",
  loading: false,
  spinner: false,
  variant: "default",
  size: "default",
  exact: false,
  block: false,
  mobileBlock: false,
  inline: false,
  textInline: false,
  active: false,
  disabled: false,
  routeActiveClass: undefined,
  inGroup: false,
});

const btnType = computed(() => {
  if (props.to && !props.disabled) return "router-link";

  if (props.href) return "a";

  return "button";
});

const btnProps = computed(() => {
  if (props.to) {
    return {
      to: props.to,
      // event: props.disabled ? '' : 'click',
      activeClass: props.routeActiveClass,
      exactActiveClass: props.routeActiveClass,
    };
  }

  if (props.href) {
    return {
      href: props.href,
      target: "_blank",
      rel: "noopener",
    };
  }

  return {
    type: props.type,
  };
});

const cssClasses = computed(() => ({
  "panel-btn-submit": props.type === "submit",
  "panel-btn-transparent": props.variant === "transparent",
  "panel-btn-link": props.variant === "link",
  "panel-btn-danger": props.variant === "danger",
  "panel-btn-small": props.size === "small",
  "panel-btn-xsmall": props.size === "xsmall",
  "panel-btn-large": props.size === "large",
  "panel-btn-block": props.block,
  "panel-btn-inline": props.inline,
  "panel-btn-dropdown-link": props.variant === "dropdown",
  "panel-btn-text-inline": props.textInline,
  "panel-btn-mobile-block": props.mobileBlock,
  "panel-btn-in-group": props.inGroup,
  active: props.active,
  disabled: props.disabled,
}));
</script>

<script lang="ts">
export default {
  name: "BaseBtn",
};
</script>

<style lang="scss" scoped>
@import "./index.scss";
</style>
