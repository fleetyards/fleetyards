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
    <Component :is="component" ref="modalComponent" v-bind="props" />
  </div>
</template>

<script lang="ts" setup>
import { ref, onMounted, onBeforeUnmount, nextTick } from "vue";
import { displayConfirm } from "@/frontend/lib/Noty";
import { useComlink } from "@/frontend/composables/useComlink";
import { useAppStore } from "@/frontend/stores/App";
import { useI18n } from "@/frontend/composables/useI18n";

type AppModalOptions = {
  component: Promise<Component>;
  title: string;
  wide: boolean;
  fixed: boolean;
  dirty: boolean;
  props: any;
};

interface AppModalComponent extends HTMLElement {
  dirty?: boolean;
}

const component = ref<Promise<Component>>();

const props = ref<any>();

const wide = ref(false);

const fixed = ref(false);

const dirty = ref(false);

const isShow = ref(false);

const isOpen = ref(false);

const comlink = useComlink();

const emit = defineEmits(["modal-closed", "modal-opened"]);

const modal = ref<HTMLElement | null>(null);

const open = (options: AppModalOptions) => {
  props.value = options.props;
  wide.value = !!options.wide;
  fixed.value = !!options.fixed;
  dirty.value = !!options.dirty;
  component.value = options.component;

  isShow.value = true;
  appStore.showOverlay();

  nextTick(() => {
    // make sure the component is present
    setTimeout(() => {
      // make sure initial animations have enough time
      isOpen.value = true;

      if (modal.value) {
        modal.value.focus();
      }

      emit("modal-opened");
    }, 100);
  });
};

const appStore = useAppStore();

const internalClose = () => {
  isOpen.value = false;
  appStore.hideOverlay();

  nextTick(() => {
    setTimeout(() => {
      isShow.value = false;
      component.value = undefined;
      props.value = undefined;
      emit("modal-closed");
    }, 300);
  });
};

const modalComponent = ref<AppModalComponent | null>(null);

const { t } = useI18n();

const close = (force = false) => {
  if (fixed.value && !force) {
    return;
  }

  if (modalComponent.value?.dirty) {
    displayConfirm({
      text: t("messages.confirm.modal.dirty"),
      onConfirm: () => {
        internalClose();
      },
    });
  } else {
    internalClose();
  }
};

onMounted(() => {
  comlink.$on("open-modal", open);
  comlink.$on("close-modal", close);
});

onBeforeUnmount(() => {
  comlink.$off("open-modal");
  comlink.$off("close-modal");
});
</script>

<script lang="ts">
export default {
  name: "AppModal",
};
</script>
