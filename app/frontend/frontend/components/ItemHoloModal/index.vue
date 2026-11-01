<script lang="ts">
export default {
  name: "ItemHoloModal",
};
</script>

<script lang="ts" setup>
import HoloViewerModal from "@/shared/components/HoloViewer/Modal/index.vue";
import { type ItemMedia } from "@/services/fyApi";
import { useItemHolo } from "@/frontend/composables/useItemHolo";
import { LOW_POWER_HOLO_SIZE_LIMIT } from "@/shared/components/HoloViewer/limits";
import { useLowPowerDevice } from "@/shared/composables/useLowPowerDevice";

type Props = {
  media: ItemMedia;
};

const props = defineProps<Props>();

const lowPower = useLowPowerDevice();

// With no switch left, a device that would have to confirm a large textured
// holo is shown the plain one instead.
const { holoModel, fallBackToPlainHolo } = useItemHolo(() => props.media, {
  canLoad: (file) =>
    !(lowPower.value && (file.size ?? 0) > LOW_POWER_HOLO_SIZE_LIMIT),
});
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
