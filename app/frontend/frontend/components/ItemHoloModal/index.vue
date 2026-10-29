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
import { type RouterLinkProps } from "vue-router";

type Props = {
  media: ItemMedia;
  textured?: boolean;
  backRoute: RouterLinkProps["to"];
};

const props = defineProps<Props>();

const { t } = useI18n();

const { texturedHolo, texturedHoloAvailable, toggleTexturedHolo, holoModel } =
  useItemHolo(() => props.media, { textured: props.textured });

useHoloQuery(() => ({ textured: texturedHolo.value }));
</script>

<template>
  <HoloViewerModal
    :models="holoModel ? [holoModel] : []"
    :back-route="backRoute"
  >
    <template #actions>
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
