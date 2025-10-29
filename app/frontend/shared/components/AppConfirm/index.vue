<script lang="ts">
export default {
  name: "AppConfirm",
};
</script>

<script lang="ts" setup>
import { AppConfirmOptions } from "@/shared/components/AppConfirm/types";
import { useComlink } from "@/shared/composables/useComlink";

const text = ref<string>();
const confirmText = ref<string>();
const cancelText = ref<string>();
const onConfirm = ref<() => void>();
const onClose = ref<() => void>();

const visible = ref(false);

const show = (options: AppConfirmOptions) => {
  text.value = options.text || "Are you sure?";
  confirmText.value = options.confirmText || "Confirm";
  cancelText.value = options.cancelText || "Cancel";
  onConfirm.value = options.onConfirm;
  onClose.value = options.onClose;

  visible.value = true;
};

const hide = () => {
  visible.value = false;
};

const comlink = useComlink();

const handleKeyDown = (event: KeyboardEvent) => {
  if (event.keyCode == 13) {
    // If enter key was pressed...
    handleConfirm();
  }
  if (event.keyCode == 27) {
    // If escape key was pressed...
    handleCancel();
  }
};

const showConfirmComlink = ref();
const hideConfirmComlink = ref();

onMounted(() => {
  showConfirmComlink.value = comlink.on("show-confirm", show);
  hideConfirmComlink.value = comlink.on("hide-confirm", hide);
  window.addEventListener("keydown", handleKeyDown);
});

onUnmounted(() => {
  showConfirmComlink.value();
  hideConfirmComlink.value();
  window.removeEventListener("keydown", handleKeyDown);
});

const handleConfirm = () => {
  onConfirm.value?.();
  hide();
};

const handleCancel = () => {
  onClose.value?.();
  hide();
};
</script>

<template>
  <Transition name="app-confirm-fade">
    <div v-if="visible" class="app-confirm">
      <div class="app-confirm__inner">
        <div class="app-confirm__text">
          {{ text }}
        </div>
        <div class="app-confirm__buttons">
          <Btn inline size="small" autofocus @click="handleCancel">{{
            cancelText
          }}</Btn>
          <Btn inline size="small" @click="handleConfirm">{{
            confirmText
          }}</Btn>
        </div>
      </div>
    </div>
  </Transition>
</template>

<style lang="scss" scoped>
@import "index";
</style>
