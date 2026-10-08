<script lang="ts">
export default {
  name: "AppModalInner",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import { useComlink } from "@/shared/composables/useComlink";

export type ModalProps = {
  title?: string;
  fixed?: boolean;
  // Runs the bottom cap while the dialog waits on something it started.
  loading?: boolean;
  // For a dialog that is not the app's modal -- one opened above it -- whose
  // close button must close only itself.
  onClose?: () => void;
};

const props = withDefaults(defineProps<ModalProps>(), {
  title: "",
  fixed: false,
  loading: false,
  onClose: undefined,
});

const comlink = useComlink();

const close = () => {
  if (props.onClose) {
    props.onClose();
    return;
  }

  comlink.emit("close-modal");
};
</script>

<template>
  <div class="modal-inner">
    <Panel :outer-spacing="false" :loading="loading">
      <div class="modal-content">
        <div class="modal-header">
          <a v-if="!fixed" class="close" aria-label="Close" @click="close">
            <i class="fa-light fa-times" />
          </a>
          <div
            v-if="$slots['header-actions']"
            class="modal-header-actions"
            :class="{ 'modal-header-actions--beside-close': !fixed }"
          >
            <slot name="header-actions" />
          </div>
          <h2
            class="modal-title"
            :class="{ 'modal-title--with-actions': $slots['header-actions'] }"
          >
            <slot name="title">
              {{ title }}
            </slot>
          </h2>
        </div>
        <div class="modal-body">
          <slot name="default" />
        </div>
      </div>
    </Panel>
    <div v-if="$slots['footer']" class="modal-footer">
      <slot name="footer" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "./index.scss";
</style>
