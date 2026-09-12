<script lang="ts">
export default {
  name: "BaseToggle",
};
</script>

<script lang="ts" setup>
import HintIcon from "@/shared/components/base/HintIcon/index.vue";

type Props = {
  active?: boolean;
  disabled?: boolean;
  loading?: boolean;
  label?: string;
  inline?: boolean;
  /*
   * Outside the button, not beside the label inside it: the label lives in the
   * control here, and anything focusable in there is both invalid inside a
   * `<button>` and a second way to fire it.
   */
  info?: string;
};

withDefaults(defineProps<Props>(), {
  active: false,
  disabled: false,
  loading: false,
  label: undefined,
  inline: false,
  info: undefined,
});

const emit = defineEmits<{
  toggle: [];
}>();

const onClick = () => {
  emit("toggle");
};
</script>

<template>
  <span class="base-toggle-field">
    <button
      type="button"
      class="base-toggle"
      :class="{
        'base-toggle--active': active,
        'base-toggle--inline': inline,
        'base-toggle--loading': loading,
      }"
      :disabled="disabled || loading"
      :data-test="`toggle-${label}`"
      @click.prevent="onClick"
    >
      <span class="base-toggle-track">
        <span class="base-toggle-knob">
          <i v-if="loading" class="fa-duotone fa-spinner fa-spin" />
        </span>
      </span>
      <span v-if="label" class="base-toggle-label">
        {{ label }}
      </span>
    </button>
    <HintIcon v-if="info" :text="info" />
  </span>
</template>

<style lang="scss" scoped>
@import "index";
</style>
