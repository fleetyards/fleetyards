<script lang="ts">
export default {
  name: "BaseTableRow",
};
</script>

<script lang="ts" setup>
import { useLongPress } from "@/shared/composables/useLongPress";

type Props = {
  clickable?: boolean;
  disabled?: boolean;
  // Holding the row asks for a selection, for a table that hides its
  // checkboxes until then.
  holdable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  clickable: false,
  disabled: false,
  holdable: false,
});

const emit = defineEmits<{
  hold: [];
}>();

const row = ref<HTMLElement>();

useLongPress({
  target: computed(() => (props.holdable ? row.value : undefined)),
  onLongPress: () => emit("hold"),
});
</script>

<template>
  <tr
    ref="row"
    class="base-table-row"
    :class="{ clickable, disabled, 'base-table-row--holdable': holdable }"
    :aria-disabled="disabled || undefined"
  >
    <slot />
  </tr>
</template>

<style lang="scss" scoped>
@import "index";
</style>
