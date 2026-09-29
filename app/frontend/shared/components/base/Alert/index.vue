<script lang="ts">
export default {
  name: "BaseAlert",
};
</script>

<script lang="ts" setup>
import { AlertSizesEnum, AlertVariantsEnum } from "./types";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  variant?: `${AlertVariantsEnum}`;
  size?: `${AlertSizesEnum}`;
  title?: string;
  icon?: string;
  dismissible?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  variant: AlertVariantsEnum.INFO,
  size: AlertSizesEnum.DEFAULT,
  title: undefined,
  icon: undefined,
  dismissible: false,
});

const emit = defineEmits<{
  dismiss: [];
}>();

const slots = useSlots();

const { t } = useI18n();

const ICONS: Record<`${AlertVariantsEnum}`, string> = {
  neutral: "fa-duotone fa-circle-info",
  info: "fa-duotone fa-circle-info",
  success: "fa-duotone fa-circle-check",
  warning: "fa-duotone fa-triangle-exclamation",
  danger: "fa-duotone fa-circle-exclamation",
};

const iconClass = computed(() => props.icon ?? ICONS[props.variant]);

const cssClasses = computed(() => [
  "base-alert",
  `base-alert--${props.variant}`,
  { "base-alert--compact": props.size === AlertSizesEnum.COMPACT },
]);
</script>

<template>
  <div :class="cssClasses" role="note" data-test="alert">
    <div class="base-alert__inner">
      <i :class="['base-alert__icon', iconClass]" aria-hidden="true" />
      <div class="base-alert__content">
        <div v-if="title" class="base-alert__title" data-test="alert-title">
          {{ title }}
        </div>
        <div v-if="slots.default" class="base-alert__body">
          <slot />
        </div>
      </div>
      <div v-if="slots.actions" class="base-alert__actions">
        <slot name="actions" />
      </div>
      <button
        v-if="dismissible"
        type="button"
        class="base-alert__dismiss"
        :aria-label="t('actions.close')"
        data-test="alert-dismiss"
        @click="emit('dismiss')"
      >
        <i class="fa-light fa-xmark" aria-hidden="true" />
      </button>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
