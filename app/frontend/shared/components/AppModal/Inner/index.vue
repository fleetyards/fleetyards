<script lang="ts">
export default {
  name: "AppModalInner",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import AppModalFooter from "@/shared/components/AppModal/Footer/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";

export type ModalProps = {
  title?: string;
  // A short line above the title naming what the dialog is about, such as the
  // ship being edited.
  eyebrow?: string;
  fixed?: boolean;
  // Runs the bottom cap while the dialog waits on something it started.
  loading?: boolean;
  // Lays the body out as a column its content can shrink into, for content
  // that scrolls a part of itself rather than letting the whole body scroll.
  fillBody?: boolean;
  // Drops the body's padding, for a table or tiles that run edge to edge and
  // pad themselves.
  flush?: boolean;
  // For a body that opens on a tab strip, whose links carry their own padding
  // above the labels.
  tabbed?: boolean;
  // For a dialog that is not the app's modal -- one opened above it -- whose
  // close button must close only itself.
  onClose?: () => void;
};

const props = withDefaults(defineProps<ModalProps>(), {
  title: "",
  eyebrow: undefined,
  fixed: false,
  loading: false,
  fillBody: false,
  flush: false,
  tabbed: false,
  onClose: undefined,
});

const slots = useSlots();

const comlink = useComlink();

const { t } = useI18n();

const titleId = useId();

// A dialog opened above the modal brings its own container - a native
// `<dialog>` - which already carries the role. A hero replaces the title row,
// so the dialog is named by the title prop instead of by the heading.
const dialogAttrs = computed(() => {
  if (props.onClose) {
    return {};
  }

  return {
    role: "dialog",
    "aria-modal": "true",
    ...(slots.hero
      ? { "aria-label": props.title || undefined }
      : { "aria-labelledby": titleId }),
  };
});

const close = () => {
  if (props.onClose) {
    props.onClose();
    return;
  }

  comlink.emit("close-modal");
};
</script>

<template>
  <div class="modal-inner" v-bind="dialogAttrs">
    <Panel :outer-spacing="false" :loading="loading">
      <div class="modal-content">
        <div v-if="$slots.hero" class="modal-hero">
          <slot name="hero" />
          <Btn
            v-if="!fixed"
            class="close modal-hero__close"
            :variant="BtnVariantsEnum.GHOST"
            :aria-label="t('actions.close')"
            @click="close"
          >
            <i class="fa-light fa-times" />
          </Btn>
        </div>
        <div
          v-else
          class="modal-header"
          :class="{ 'modal-header--tabbed': tabbed }"
        >
          <div class="modal-heading">
            <p v-if="eyebrow || $slots.eyebrow" class="modal-eyebrow">
              <slot name="eyebrow">
                {{ eyebrow }}
              </slot>
            </p>
            <h2 :id="titleId" class="modal-title">
              <slot name="title">
                {{ title }}
              </slot>
            </h2>
          </div>
          <div v-if="$slots['header-actions']" class="modal-header-actions">
            <slot name="header-actions" />
          </div>
          <Btn
            v-if="!fixed"
            class="close"
            :variant="BtnVariantsEnum.GHOST"
            :aria-label="t('actions.close')"
            @click="close"
          >
            <i class="fa-light fa-times" />
          </Btn>
        </div>
        <div
          class="modal-body"
          :class="{
            'modal-body--fill': fillBody,
            'modal-body--flush': flush,
          }"
        >
          <slot name="default" />
        </div>
      </div>
    </Panel>
    <AppModalFooter v-if="$slots['footer'] || $slots['footer-start']">
      <template v-if="$slots['footer-start']" #start>
        <slot name="footer-start" />
      </template>
      <slot name="footer" />
    </AppModalFooter>
  </div>
</template>

<style lang="scss" scoped>
@import "./index.scss";
</style>
