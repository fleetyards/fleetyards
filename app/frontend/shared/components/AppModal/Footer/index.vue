<script lang="ts">
export default {
  name: "AppModalFooter",
};
</script>

<script lang="ts" setup>
import { BTN_CONTAINER } from "@/shared/components/base/Btn/context";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";

// A component of its own so the medium size reaches the footer's buttons and
// not the ones in the modal body.
provide(BTN_CONTAINER, {
  container: "footer",
  size: computed(() => BtnSizesEnum.MD),
  block: computed(() => false),
});
</script>

<template>
  <div class="modal-footer">
    <div v-if="$slots.start" class="modal-footer__start">
      <slot name="start" />
    </div>
    <div class="modal-footer__end">
      <slot />
    </div>
  </div>
</template>

<style lang="scss" scoped>
// What the dock says about the work rather than commits it - a selection's
// count, Back, a destructive action - sits apart from the closing actions.
.modal-footer__start {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.5rem;
  margin-right: auto;
  padding-left: 4px;
  color: var(--color-text-dim, #959595);
}

.modal-footer__end {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: flex-end;
  gap: 0.5rem;
  margin-left: auto;
}
</style>
