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
import { popoverLayerKey } from "@/shared/components/Popover/layer";
import { type AppModalOptions } from "./types";

interface ModalComponent extends HTMLElement {
  dirty?: boolean;
  // Replaces the unsaved-changes wording for content whose close loses
  // something other than typed input.
  dirtyText?: string;
}

const modal = ref<HTMLElement | undefined>();

const modalComponent = ref<ModalComponent | undefined>();

const component = ref<Raw<Component> | undefined>();

const componentProps = ref({});

const wide = ref(false);
const large = ref(false);

const fixed = ref(false);

const fullscreen = ref(false);

const dirty = ref(false);

const isShow = ref(false);

const isOpen = ref(false);

// An edit inside one of the content's forms that has not been submitted yet.
// Content that knows better exposes `dirty` itself.
const formEdited = ref(false);

const onFormEdit = (event: Event) => {
  if ((event.target as Element | null)?.closest?.("form")) {
    formEdited.value = true;
  }
};

// Every form modal saves by submitting, and most close themselves afterwards
// without forcing it, so a submit is what clears the edit.
const onFormSubmit = () => {
  formEdited.value = false;
};

// Matches `.app-modal` in index.scss, so a popover opened from the modal's
// content is placed above it rather than underneath.
provide(popoverLayerKey, 1050);

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

// Counts the opens, so a hide that finishes after the next modal opened leaves
// that one alone: a page that opens a modal on arrival does so while the
// route change is still closing the last one.
let openCount = 0;

const open = async (options: AppModalOptions) => {
  openCount += 1;
  componentProps.value = options.props;
  wide.value = !!options.wide;
  large.value = !!options.large;
  fixed.value = !!options.fixed;
  dirty.value = !!options.dirty;
  formEdited.value = false;
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

// A modal belongs to the page it was opened on. Leaving the page -- a link
// inside the modal, the browser's back button -- takes it along, without
// asking: the page it was editing is gone either way. A query change stays on
// the page, so it leaves the modal open.
const route = useRoute();

//
// A modal the address asks for (`?modal=support`) belongs to the address
// instead, and stays as long as the address keeps asking for it.
watch(
  () => route.path,
  () => {
    if (isShow.value && !route.query.modal) void internalHide();
  },
);

const { displayConfirm } = useAppNotifications();

const close = async (force = false) => {
  if (fixed.value && !force) {
    return;
  }

  // A forced close is the modal closing itself after it saved: what was typed
  // is not lost, so there is nothing to confirm.
  if (!force && (modalComponent.value?.dirty ?? formEdited.value)) {
    displayConfirm({
      text:
        modalComponent.value?.dirtyText ?? t("appModal.messages.confirm.dirty"),
      onConfirm: async () => {
        await internalHide();
      },
    });
  } else {
    await internalHide();
  }
};

const internalHide = async () => {
  const closing = openCount;

  isOpen.value = false;

  overlayStore.hide();

  await nextTick(function onHide() {
    setTimeout(() => {
      if (closing !== openCount) return;

      isShow.value = false;
      component.value = undefined;
      componentProps.value = {};

      emit("modal-closed");

      // Listeners may tear down what the content's unmount hooks still use.
      void nextTick(() => comlink.emit("modal-closed"));
    }, 300);
  });
};

const modalClasses = computed(() => {
  return {
    in: isOpen.value,
    show: isShow.value,
    wide: wide.value,
    large: large.value,
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
    @input="onFormEdit"
    @change="onFormEdit"
    @submit.capture="onFormSubmit"
  >
    <div class="modal-dialog" :class="modalDialogClasses">
      <Component :is="component" ref="modalComponent" v-bind="componentProps" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "./index.scss";
</style>
