<script lang="ts">
export default {
  name: "HoloViewerModal",
};
</script>

<script lang="ts" setup>
import HoloViewer, {
  type HoloModel,
} from "@/shared/components/HoloViewer/index.vue";
import AppModalCloseBtn from "@/shared/components/AppModal/CloseBtn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import { useComlink } from "@/shared/composables/useComlink";

type Props = {
  models: HoloModel[];
  // Sized for ships: under a component or a piece of equipment its cells
  // dwarf the item.
  grid?: boolean;
  // The 3D view is taken down while Quick Look converts the holo: a phone
  // does not hold both copies.
  suspended?: boolean;
};

withDefaults(defineProps<Props>(), {
  grid: true,
  suspended: false,
});

const emit = defineEmits<{ unavailable: [] }>();

const comlink = useComlink();

const close = () => {
  comlink.emit("close-modal");
};
</script>

<template>
  <div class="holo-viewer-modal">
    <!-- Top right is the item shown, bottom right the scene it is shown in. -->
    <div class="holo-viewer-modal__controls">
      <!-- Groups of their own, beside the one holding the close button. -->
      <slot name="groups" />
      <BtnGroup>
        <slot name="controls" />
        <AppModalCloseBtn data-test="holo-viewer-modal-close" @click="close" />
      </BtnGroup>
    </div>
    <HoloViewer
      v-if="!suspended"
      :models="models"
      :autoRotate="false"
      zoomable
      panable
      :grid="grid"
      backgrounds
      edge-to-edge
      @unavailable="emit('unavailable')"
    />
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
