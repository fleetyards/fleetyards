<script lang="ts">
export default {
  name: "AppModal",
};
</script>

<script lang="ts" setup>
import { defineAsyncComponent } from "vue";
import type { Component, Raw } from "vue";
import { useComlink } from "@/shared/composables/useComlink";
import { useOverlayStore } from "@/shared/stores/overlay";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

export type AppModalOptions = {
  component: () => Promise<Component>;
  title?: string;
  wide?: boolean;
  fixed?: boolean;
  dirty?: boolean;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  props?: any;
};

interface ModalComponent extends HTMLElement {
  dirty?: boolean;
}

const modal = ref<HTMLElement | undefined>();

const modalComponent = ref<ModalComponent | undefined>();

const component = ref<Raw<Component> | undefined>();

const componentProps = ref({});

const wide = ref(false);

const fixed = ref(false);

const dirty = ref(false);

const isShow = ref(false);

const isOpen = ref(false);

const comlink = useComlink();

onMounted(() => {
  comlink.on("open-modal", open);
  comlink.on("close-modal", close);
});

onUnmounted(() => {
  comlink.off("open-modal", open);
  comlink.off("close-modal", close);
});

const emit = defineEmits(["modal-opened", "modal-closed"]);

const overlayStore = useOverlayStore();

const open = (options: AppModalOptions) => {
  componentProps.value = options.props;
  wide.value = !!options.wide;
  fixed.value = !!options.fixed;
  dirty.value = !!options.dirty;
  component.value = markRaw(defineAsyncComponent(options.component));

  isShow.value = true;

  overlayStore.show();

  nextTick(() => {
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

const close = (force = false) => {
  if (fixed.value && !force) {
    return;
  }

  if (modalComponent.value?.dirty) {
    displayConfirm({
      text: t("appModal.messages.confirm.dirty"),
      onConfirm: () => {
        internalHide();
      },
    });
  } else {
    internalHide();
  }
};

const internalHide = () => {
  isOpen.value = false;

  overlayStore.hide();

  nextTick(function onHide() {
    setTimeout(() => {
      isShow.value = false;
      component.value = undefined;
      componentProps.value = {};

      emit("modal-closed");
    }, 300);
  });
};

defineExpose({
  open,
  close,
});
</script>

<template>
  <div
    v-if="component"
    ref="modal"
    :class="{
      in: isOpen,
      show: isShow,
      wide: wide,
      fixed: fixed,
    }"
    class="app-modal fade"
    @click.self="() => close()"
  >
    <div class="modal-dialog">
      <Component :is="component" ref="modalComponent" v-bind="componentProps" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "./index.scss";
</style>
