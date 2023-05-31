<template>
  <component
    :is="btnType"
    v-bind="btnProps"
    :class="cssClasses"
    :disabled="disabled || loading"
  >
    <BtnInner :loading="loading">
      <slot />
    </BtnInner>
  </component>
</template>

<script lang="ts" setup>
import type { RouteLocationRaw } from "vue-router";
import BtnInner from "@/embed/components/Btn/Inner/index.vue";

type Props = {
  loading?: boolean;
  to?: RouteLocationRaw;
  href?: string;
  type?: "button" | "submit";
  variant?: "default" | "transparent" | "link" | "danger";
  size?: "default" | "small" | "large";
  exact?: boolean;
  block?: boolean;
  mobileBlock?: boolean;
  inline?: boolean;
  textInline?: boolean;
  active?: boolean;
  disabled?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  to: undefined,
  href: undefined,
  type: "button",
  variant: "default",
  size: "default",
  exact: false,
  block: false,
  mobileBlock: false,
  inline: false,
  textInline: false,
  active: false,
  disabled: false,
});

const btnType = computed(() => {
  if (props.to) return "router-link";

  if (props.href) return "a";

  return "button";
});

const btnProps = computed(() => {
  if (props.to) {
    return {
      to: props.to,
      exact: props.exact,
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

const cssClasses = computed(() => {
  return {
    "panel-btn": true,
    "panel-btn-submit": props.type === "submit",
    "panel-btn-transparent": props.variant === "transparent",
    "panel-btn-link": props.variant === "link",
    "panel-btn-danger": props.variant === "danger",
    "panel-btn-small": props.size === "small",
    "panel-btn-large": props.size === "large",
    "panel-btn-block": props.block,
    "panel-btn-inline": props.inline,
    "panel-btn-text-inline": props.textInline,
    "panel-btn-mobile-block": props.mobileBlock,
    active: props.active,
  };
});
</script>

<script lang="ts">
export default {
  name: "BaseBtn",
};
</script>
