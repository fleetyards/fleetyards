<script lang="ts">
export default {
  name: "BaseToggle",
};
</script>

<script lang="ts" setup>
type Props = {
  active?: boolean;
  disabled?: boolean;
  loading?: boolean;
  label?: string;
  inline?: boolean;
};

withDefaults(defineProps<Props>(), {
  active: false,
  disabled: false,
  loading: false,
  label: undefined,
  inline: false,
});

const emit = defineEmits<{
  toggle: [];
}>();

const onClick = () => {
  emit("toggle");
};
</script>

<template>
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
</template>

<style lang="scss" scoped>
@import "index";
</style>
