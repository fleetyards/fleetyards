<script lang="ts">
export default {
  name: "BaseTableRow",
};
</script>

<script lang="ts" setup>
import { useEventListener } from "@vueuse/core";
import { useLongPress } from "@/shared/composables/useLongPress";

type Props = {
  clickable?: boolean;
  disabled?: boolean;
  // Holding the row asks for a selection, for a table that hides its
  // checkboxes until then.
  holdable?: boolean;
  // Takes a tap before anything inside the row sees it - a linked name, an
  // action - and reports it instead: a row being picked from does not follow
  // its links.
  intercept?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  clickable: false,
  disabled: false,
  holdable: false,
  intercept: false,
});

const emit = defineEmits<{
  hold: [];
  intercepted: [];
}>();

const row = ref<HTMLElement>();

useLongPress({
  target: computed(() => (props.holdable ? row.value : undefined)),
  onLongPress: () => emit("hold"),
});

// After the hold's own guard, which stops the click a lifted finger sends so
// the row it just picked is not unpicked again.
useEventListener(
  row,
  "click",
  (event: MouseEvent) => {
    if (!props.intercept) {
      return;
    }

    event.preventDefault();
    event.stopPropagation();
    emit("intercepted");
  },
  { capture: true },
);
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
