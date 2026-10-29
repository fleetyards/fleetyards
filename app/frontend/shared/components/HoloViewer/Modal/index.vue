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
};

defineProps<Props>();

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
      grid
      backgrounds
      @unavailable="emit('unavailable')"
    />
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
