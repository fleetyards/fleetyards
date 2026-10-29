<script lang="ts">
export default {
  name: "HoloViewerModal",
};
</script>

<script lang="ts" setup>
import HoloViewer, {
  type HoloModel,
} from "@/shared/components/HoloViewer/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import { useComlink } from "@/shared/composables/useComlink";
import { RouterLinkProps } from "vue-router";

type Props = {
  models: HoloModel[];
  backRoute?: RouterLinkProps["to"];
};

defineProps<Props>();

const comlink = useComlink();

const close = () => {
  comlink.emit("close-modal");
};
</script>

<template>
  <div class="holo-viewer-modal">
    <router-link
      v-if="backRoute"
      :to="backRoute"
      class="close"
      aria-label="Close"
      @click="close"
    >
      <i class="fa-light fa-times" />
    </router-link>
    <a v-else class="close" aria-label="Close" @click="close">
      <i class="fa-light fa-times" />
    </a>
    <!-- Top right is the item shown, bottom right the scene it is shown in. -->
    <div v-if="$slots.controls" class="holo-viewer-modal__controls">
      <BtnGroup>
        <slot name="controls" />
      </BtnGroup>
    </div>
    <HoloViewer
      :models="models"
      :autoRotate="false"
      zoomable
      panable
      grid
      backgrounds
    />
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
