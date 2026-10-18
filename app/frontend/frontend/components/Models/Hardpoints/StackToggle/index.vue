<script lang="ts">
export default {
  name: "HardpointStackToggle",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  // On a row split out of a stack, which folds it back.
  split?: boolean;
};

withDefaults(defineProps<Props>(), {
  split: false,
});

const emit = defineEmits<{ toggle: [] }>();

const { t } = useI18n();
</script>

<template>
  <!-- The loadout editor's stack control: split a stack into its slots, or
    fold a split one back. -->
  <button
    type="button"
    class="hardpoint-stack-toggle"
    :aria-expanded="split"
    :aria-label="t(split ? 'labels.collapse' : 'labels.expand')"
    data-test="hardpoint-stack-toggle"
    @click.stop="emit('toggle')"
  >
    <i
      class="fa-solid"
      :class="split ? 'fa-compress' : 'fa-layer-group'"
      aria-hidden="true"
    />
  </button>
</template>

<style lang="scss" scoped>
.hardpoint-stack-toggle {
  flex: none;
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0;
  background: none;
  border: 1px solid rgba($gray-light, 0.35);
  border-radius: 6px;
  color: $gray-light;
  font-size: 11px;
  cursor: pointer;
  transition:
    color 0.15s,
    border-color 0.15s;

  &:hover {
    color: lighten($text-color, 15%);
    border-color: rgba($gray-light, 0.6);
  }

  &:focus-visible {
    outline: 2px solid var(--color-primary, #428bca);
    outline-offset: 2px;
  }
}
</style>
