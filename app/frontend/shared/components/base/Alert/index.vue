<script lang="ts">
export default {
  name: "BaseAlert",
};
</script>

<script lang="ts" setup>
import { AlertVariantsEnum } from "./types";

type Props = {
  variant?: `${AlertVariantsEnum}`;
  icon?: string;
};

const props = withDefaults(defineProps<Props>(), {
  variant: AlertVariantsEnum.INFO,
  icon: undefined,
});

const slots = useSlots();

const ICONS: Record<`${AlertVariantsEnum}`, string> = {
  info: "fa-duotone fa-circle-info",
  success: "fa-duotone fa-circle-check",
  warning: "fa-duotone fa-triangle-exclamation",
  danger: "fa-duotone fa-circle-exclamation",
};

const iconClass = computed(() => props.icon ?? ICONS[props.variant]);
</script>

<template>
  <div
    :class="['base-alert', `base-alert--${variant}`]"
    role="note"
    data-test="alert"
  >
    <i :class="['base-alert__icon', iconClass]" aria-hidden="true" />
    <div class="base-alert__body">
      <slot />
    </div>
    <div v-if="slots.actions" class="base-alert__actions">
      <slot name="actions" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
