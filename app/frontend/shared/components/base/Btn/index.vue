<script lang="ts">
export default {
  name: "BaseBtn",
};
</script>

<script lang="ts" setup>
import BtnInner from "@/shared/components/base/Btn/Inner/index.vue";
import type { SpinnerAlignment } from "@/shared/components/SmallLoader/index.vue";
import type { RouterLinkProps } from "vue-router";
import {
  BtnTypesEnum,
  BtnVariantsEnum,
  BtnSizesEnum,
} from "@/shared/components/base/Btn/types";

export type Props = {
  to?: RouterLinkProps["to"];
  href?: string;
  type?: `${BtnTypesEnum}`;
  loading?: boolean;
  spinner?: boolean | SpinnerAlignment;
  variant?: `${BtnVariantsEnum}`;
  size?: `${BtnSizesEnum}`;
  exact?: boolean;
  block?: boolean;
  mobileBlock?: boolean;
  inline?: boolean;
  textInline?: boolean;
  active?: boolean;
  disabled?: boolean;
  routeActiveClass?: string;
};

const props = withDefaults(defineProps<Props>(), {
  to: undefined,
  href: undefined,
  type: BtnTypesEnum.BUTTON,
  loading: false,
  spinner: false,
  variant: BtnVariantsEnum.DEFAULT,
  size: BtnSizesEnum.DEFAULT,
  exact: false,
  block: false,
  mobileBlock: false,
  inline: false,
  textInline: false,
  active: false,
  disabled: false,
  routeActiveClass: undefined,
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

const cssClasses = computed(() => ({
  "panel-btn-submit": props.type === BtnTypesEnum.SUBMIT,
  "panel-btn-transparent": props.variant === BtnVariantsEnum.TRANSPARENT,
  "panel-btn-link": props.variant === BtnVariantsEnum.LINK,
  "panel-btn-danger": props.variant === BtnVariantsEnum.DANGER,
  "panel-btn-small": props.size === BtnSizesEnum.SMALL,
  "panel-btn-xsmall": props.size === BtnSizesEnum.X_SMALL,
  "panel-btn-large": props.size === BtnSizesEnum.LARGE,
  "panel-btn-block": props.block,
  "panel-btn-inline": props.inline,
  "panel-btn-text-inline": props.textInline,
  "panel-btn-mobile-block": props.mobileBlock,
  active: props.active,
  disabled: props.disabled,
}));
</script>

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

<style lang="scss" scoped>
@import "./index.scss";
</style>
