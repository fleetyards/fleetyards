<script lang="ts">
export default {
  name: "HoloViewerModal",
};
</script>

<script lang="ts" setup>
import HoloViewer, {
  type HoloModel,
} from "@/shared/components/HoloViewer/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  models: HoloModel[];
  // Sized for ships: under a component or a piece of equipment its cells
  // dwarf the item.
  grid?: boolean;
};

withDefaults(defineProps<Props>(), {
  grid: true,
});

const emit = defineEmits<{ unavailable: [] }>();

const { t } = useI18n();

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
        <Btn
          :aria-label="t('actions.close')"
          v-tooltip="t('actions.close')"
          data-test="holo-viewer-modal-close"
          @click="close"
        >
          <i class="fa-light fa-times" />
        </Btn>
      </BtnGroup>
    </div>
    <HoloViewer
      :models="models"
      :autoRotate="false"
      zoomable
      panable
      :grid="grid"
      backgrounds
      @unavailable="emit('unavailable')"
    />
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
