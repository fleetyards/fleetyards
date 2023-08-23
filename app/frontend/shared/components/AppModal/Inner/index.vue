<template>
  <div class="modal-inner">
    <Panel :outer-spacing="false">
      <div class="modal-content">
        <div class="modal-header">
          <a v-if="!fixed" class="close" aria-label="Close" @click="close">
            <i class="fal fa-times" />
          </a>
          <h2 class="modal-title">
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
      <div class="clearfix" />
    </div>
  </div>
</template>

<script lang="ts" setup>
import Panel from "@/shared/components/Panel/index.vue";
import { useComlink } from "@/shared/composables/useComlink";

export type ModalProps = {
  title?: string;
  fixed?: boolean;
};

withDefaults(defineProps<ModalProps>(), {
  title: "",
  fixed: false,
});

const comlink = useComlink();

const close = () => {
  comlink.emit("close-modal");
};
</script>

<script lang="ts">
export default {
  name: "AppModalInner",
};
</script>

<style lang="scss" scoped>
@import "./index.scss";
</style>
