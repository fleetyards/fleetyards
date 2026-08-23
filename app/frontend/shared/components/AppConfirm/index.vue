<script lang="ts">
export default {
  name: "AppConfirm",
};
</script>

<script lang="ts" setup>
import { AppConfirmOptions } from "@/shared/components/AppConfirm/types";
import { useComlink } from "@/shared/composables/useComlink";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { afterNextPaint } from "@/shared/utils/Transitions";

const text = ref<string>();
const confirmText = ref<string>();
const cancelText = ref<string>();
const onConfirm = ref<() => void | Promise<unknown>>();
const onClose = ref<() => void | Promise<unknown>>();

const visible = ref(false);

// Mounted, then moved: `visible` puts the dialog in the DOM at its start
// position, `entered` animates it in.
const entered = ref(false);

const show = (options: AppConfirmOptions) => {
  text.value = options.text || "Are you sure?";
  confirmText.value = options.confirmText || "Confirm";
  cancelText.value = options.cancelText || "Cancel";
  onConfirm.value = options.onConfirm;
  onClose.value = options.onClose;

  visible.value = true;

  // Same two-step the app modal uses: mount at the start position, let it paint,
  // then add `in` so the dialog travels. Setting both in one frame is what made
  // this snap into place.
  afterNextPaint(() => {
    entered.value = true;
  });
};

const hide = () => {
  entered.value = false;
  visible.value = false;
  onConfirm.value = undefined;
  onClose.value = undefined;
};

const comlink = useComlink();

const handleKeyDown = (event: KeyboardEvent) => {
  if (!visible.value) return;

  if (event.key === "Enter") {
    handleConfirm().catch(console.error);
  }
  if (event.key === "Escape") {
    handleCancel().catch(console.error);
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

const handleConfirm = async () => {
  await onConfirm.value?.();
  hide();
};

const handleCancel = async () => {
  await onClose.value?.();
  hide();
};
</script>

<template>
  <div
    v-if="visible"
    class="app-confirm fade"
    :class="{ in: entered }"
    data-test="confirm-dialog"
    @click.self="handleCancel"
  >
    <div class="app-confirm__dialog">
      <Panel :outer-spacing="false">
        <PanelBody>
          <!-- eslint-disable-next-line vue/no-v-html -->
          <div class="app-confirm__text" v-html="text" />
        </PanelBody>
      </Panel>
      <!-- Outside the panel, like the modal footer: the actions belong to the
           dialog, not to the surface holding the question. -->
      <div class="app-confirm__buttons" data-test="confirm-buttons">
        <Btn data-test="confirm-cancel" autofocus @click="handleCancel">{{
          cancelText
        }}</Btn>
        <Btn data-test="confirm-ok" @click="handleConfirm">{{
          confirmText
        }}</Btn>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
