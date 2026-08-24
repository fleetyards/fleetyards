<script lang="ts">
export default {
  name: "AppConfirm",
};
</script>

<script lang="ts" setup>
import {
  AppConfirmTonesEnum,
  type AppConfirmOptions,
} from "@/shared/components/AppConfirm/types";
import { useComlink } from "@/shared/composables/useComlink";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelTonesEnum } from "@/shared/components/base/Panel/types";
import {
  BtnTonesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { afterNextPaint } from "@/shared/utils/Transitions";

const text = ref<string>();
const confirmText = ref<string>();
const cancelText = ref<string>();
const onConfirm = ref<() => void | Promise<unknown>>();
const onClose = ref<() => void | Promise<unknown>>();

const tone = ref<`${AppConfirmTonesEnum}`>(AppConfirmTonesEnum.NEUTRAL);

/*
 * Three tones onto what the panel already has: the caps are the accent, and the
 * panel's `highlight` gold is the caution colour it offers - there is no warning
 * tone to reach for, and inventing one for this dialog would put a fourth accent
 * treatment into the design.
 */
const panelTone = computed(() => {
  if (tone.value === AppConfirmTonesEnum.DANGER) return PanelTonesEnum.ERROR;
  if (tone.value === AppConfirmTonesEnum.WARNING) {
    return PanelTonesEnum.HIGHLIGHT;
  }

  return PanelTonesEnum.NEUTRAL;
});

// Only a destroying confirm tones its committing button. A warning is not a
// danger, and dressing it as one is how a warning stops being read.
const confirmButtonTone = computed(() =>
  tone.value === AppConfirmTonesEnum.DANGER
    ? BtnTonesEnum.DANGER
    : BtnTonesEnum.NEUTRAL,
);

const confirmRef = ref<{ $el?: HTMLElement } | null>(null);

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
  tone.value = options.tone || AppConfirmTonesEnum.NEUTRAL;

  visible.value = true;

  // Same two-step the app modal uses: mount at the start position, let it paint,
  // then add `in` so the dialog travels. Setting both in one frame is what made
  // this snap into place.
  afterNextPaint(() => {
    entered.value = true;

    // Focus the default action, so Enter is handled natively by the button
    // rather than by a window listener racing it.
    confirmRef.value?.$el?.focus();
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

  /*
   * Enter is deliberately absent: the confirming button holds focus and the
   * browser already activates it. Handling it here as well meant Enter fired the
   * focused button *and* this handler - and with autofocus previously on Cancel,
   * one keypress ran both outcomes.
   */
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
      <Panel :tone="panelTone" :outer-spacing="false">
        <PanelBody>
          <!-- eslint-disable-next-line vue/no-v-html -->
          <div class="app-confirm__text" v-html="text" />
        </PanelBody>
      </Panel>
      <!-- Outside the panel, like the modal footer: the actions belong to the
           dialog, not to the surface holding the question. -->
      <div class="app-confirm__buttons" data-test="confirm-buttons">
        <Btn
          :variant="BtnVariantsEnum.GHOST"
          data-test="confirm-cancel"
          @click="handleCancel"
        >
          {{ cancelText }}
        </Btn>
        <Btn
          ref="confirmRef"
          :tone="confirmButtonTone"
          data-test="confirm-ok"
          @click="handleConfirm"
        >
          {{ confirmText }}
        </Btn>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
