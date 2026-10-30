<script lang="ts">
export default {
  name: "ItemHoloModal",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import HoloViewerModal from "@/shared/components/HoloViewer/Modal/index.vue";
import { type ItemMedia } from "@/services/fyApi";
import { useItemHolo } from "@/frontend/composables/useItemHolo";
import { useHoloQuery } from "@/frontend/composables/useHoloQuery";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  media: ItemMedia;
  textured?: boolean;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { texturedHolo, texturedHoloAvailable, toggleTexturedHolo, holoModel } =
  useItemHolo(() => props.media, { textured: props.textured });

useHoloQuery(() => ({
  textured: texturedHoloAvailable.value && texturedHolo.value,
}));

// A textured holo that will not draw falls back to the plain one, and the
// address with it, so a copied link does not carry the failure on.
const holoUnavailable = () => {
  if (holoModel.value?.textured) texturedHolo.value = false;
};
</script>

<template>
  <HoloViewerModal
    :models="holoModel ? [holoModel] : []"
    :grid="false"
    @unavailable="holoUnavailable"
  >
    <template #controls>
      <Btn
        v-if="texturedHoloAvailable"
        :active="texturedHolo"
        v-tooltip="t('labels.texturedHolo')"
        :aria-label="t('labels.texturedHolo')"
        data-test="item-holo-modal-textured"
        @click="toggleTexturedHolo"
      >
        <i class="fa-duotone fa-palette" />
      </Btn>
    </template>
  </HoloViewerModal>
</template>
