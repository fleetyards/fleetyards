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
  <HoloViewerModal
    :models="holoModel ? [holoModel] : []"
    :grid="false"
    @unavailable="fallBackToPlainHolo"
  />
</template>
