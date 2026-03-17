<script lang="ts">
export default {
  name: "AppModal",
};
</script>

<script lang="ts" setup>
import { defineAsyncComponent } from "vue";
import type { Raw } from "vue";
import { useComlink } from "@/shared/composables/useComlink";
import { useOverlayStore } from "@/shared/stores/overlay";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { type AppModalOptions } from "./types";

interface ModalComponent extends HTMLElement {
  dirty?: boolean;
}

const modal = ref<HTMLElement | undefined>();

const modalComponent = ref<ModalComponent | undefined>();

const component = ref<Raw<Component> | undefined>();

const componentProps = ref({});

const wide = ref(false);

const fixed = ref(false);

const fullscreen = ref(false);

const dirty = ref(false);

const isShow = ref(false);

const isOpen = ref(false);

const comlink = useComlink();

const onOpenModalComlink = ref();
const onCloseModalComlink = ref();

onMounted(() => {
  onOpenModalComlink.value = comlink.on("open-modal", open);
  onCloseModalComlink.value = comlink.on("close-modal", close);
});

onUnmounted(() => {
  onOpenModalComlink.value();
  onCloseModalComlink.value();
});

const emit = defineEmits(["modal-opened", "modal-closed"]);

const overlayStore = useOverlayStore();

const open = async (options: AppModalOptions) => {
  componentProps.value = options.props;
  wide.value = !!options.wide;
  fixed.value = !!options.fixed;
  dirty.value = !!options.dirty;
  fullscreen.value = !!options.fullscreen;
  component.value = markRaw(defineAsyncComponent(options.component));

  isShow.value = true;

  overlayStore.show();

  await nextTick(() => {
    // make sure the component is present
    setTimeout(() => {
      // make sure initial animations have enough time
      isOpen.value = true;

      modal.value?.focus();

      emit("modal-opened");
    }, 100);
  });
};

const { t } = useI18n();

const { displayConfirm } = useAppNotifications();

const close = async (force = false) => {
  if (fixed.value && !force) {
    return;
  }

  if (modalComponent.value?.dirty) {
    displayConfirm({
      text: t("appModal.messages.confirm.dirty"),
      onConfirm: async () => {
        await internalHide();
      },
    });
  } else {
    await internalHide();
  }
};

const internalHide = async () => {
  isOpen.value = false;

  overlayStore.hide();

  await nextTick(function onHide() {
    setTimeout(() => {
      isShow.value = false;
      component.value = undefined;
      componentProps.value = {};

      emit("modal-closed");
    }, 300);
  });
};

const modalClasses = computed(() => {
  return {
    in: isOpen.value,
    show: isShow.value,
    wide: wide.value,
    fixed: fixed.value,
    fullscreen: fullscreen.value,
  };
});

const modalDialogClasses = computed(() => {
  return {
    fullscreen: fullscreen.value,
  };
});

defineExpose({
  open,
  close,
});
</script>

<template>
  <div
    v-if="component"
    ref="modal"
    :class="modalClasses"
    class="app-modal fade"
    data-test="modal"
    @click.self="() => close()"
  >
    <div class="modal-dialog" :class="modalDialogClasses">
      <Component :is="component" ref="modalComponent" v-bind="componentProps" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "./index.scss";
</style>
