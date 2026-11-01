<script lang="ts">
export default {
  name: "ItemHoloModal",
};
</script>

<script lang="ts" setup>
import HoloViewerModal from "@/shared/components/HoloViewer/Modal/index.vue";
import { type ItemMedia } from "@/services/fyApi";
import { useItemHolo } from "@/frontend/composables/useItemHolo";

type Props = {
  media: ItemMedia;
};

const props = defineProps<Props>();

const { holoModel, fallBackToPlainHolo } = useItemHolo(() => props.media);
</script>

<template>
  <!-- Keyed by the holo, so the plain one gets a fresh viewer instead of the
       one the textured holo lost its WebGL context in. -->
  <HoloViewerModal
    :key="holoModel?.path"
    :models="holoModel ? [holoModel] : []"
    :grid="false"
    @unavailable="fallBackToPlainHolo"
  />
</template>
