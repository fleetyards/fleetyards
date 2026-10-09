<script lang="ts">
export default {
  name: "AppModalFooter",
};
</script>

<script lang="ts" setup>
import { BTN_CONTAINER } from "@/shared/components/base/Btn/context";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";

// A component of its own so the large size reaches the footer's buttons and
// not the ones in the modal body.
provide(BTN_CONTAINER, {
  container: "footer",
  size: computed(() => BtnSizesEnum.LG),
  block: computed(() => false),
});
</script>

<template>
  <div class="modal-footer">
    <slot />
  </div>
</template>
