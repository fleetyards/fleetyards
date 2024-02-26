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

<script lang="ts" setup>
import { defineAsyncComponent } from "vue";
import type { Component, Raw } from "vue";
import { useComlink } from "@/shared/composables/useComlink";
import { useOverlayStore } from "@/shared/stores/overlay";
import type { I18nPluginOptions } from "@/shared/plugins/I18n";
import type { NotyPluginOptions } from "@/shared/plugins/Noty";

export type AppModalOptions = {
  component: () => Promise<Component>;
  title?: string;
  wide?: boolean;
  fixed?: boolean;
  dirty?: boolean;
  props?: unknown;
};

interface ModalComponent extends HTMLElement {
  dirty?: boolean;
}

const modal = ref<HTMLElement | undefined>();

const modalComponent = ref<ModalComponent | undefined>();

const component = ref<Raw<Component> | undefined>();

const componentProps = ref<unknown>();

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

const noty = inject<NotyPluginOptions>("noty");

const i18n = inject<I18nPluginOptions>("i18n");

const close = (force = false) => {
  if (fixed.value && !force) {
    return;
  }

  if (modalComponent.value?.dirty) {
    noty?.displayConfirm({
      text: i18n?.t("appModal.messages.confirm.dirty"),
      onConfirm: () => {
        internalClose();
      },
    });
  } else {
    internalClose();
  }
};

const internalClose = () => {
  isOpen.value = false;

  overlayStore.hide();

  nextTick(function onClose() {
    setTimeout(() => {
      isShow.value = false;
      component.value = undefined;
      componentProps.value = null;

      emit("modal-closed");
    }, 300);
  });
};

defineExpose({
  open,
  close,
});
</script>

<script lang="ts">
export default {
  name: "AppModal",
};
</script>

<style lang="scss" scoped>
@import "./index.scss";
</style>
