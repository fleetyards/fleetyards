<template>
  <div class="modal-dialog">
    <Panel :outer-spacing="false">
      <div class="modal-content">
        <div class="modal-header">
          <a class="close" aria-label="Close" @click="close">
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
import { defineProps } from "vue";
import Panel from "@/frontend/core/components/Panel/index.vue";
import { useComlink } from "@/frontend/composables/useComlink";

export type ModalProps = {
  title?: string;
};

defineProps<ModalProps>();

const comlink = useComlink();

const close = () => {
  comlink.$emit("close-modal");
};
</script>

<script lang="ts">
export default {
  name: "AppModalInner",
};
</script>
