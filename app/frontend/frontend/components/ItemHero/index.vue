<script lang="ts">
export default {
  name: "ItemHero",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { type MediaFile } from "@/services/fyApi";
import { LOW_POWER_HOLO_SIZE_LIMIT } from "@/shared/components/HoloViewer/limits";
import { useI18n } from "@/shared/composables/useI18n";
import { useLowPowerDevice } from "@/shared/composables/useLowPowerDevice";
import { useMobile } from "@/shared/composables/useMobile";

type Props = {
  image?: MediaFile | null;
  holo?: MediaFile | null;
  name: string;
  testId: string;
};

const props = defineProps<Props>();

const HoloViewer = defineAsyncComponent(
  () => import("@/shared/components/HoloViewer/index.vue"),
);

// An item's holo keeps the game's entity frame, whose default camera looks at
// the back of it; this starts it side on.
const HOLO_AZIMUTH = -90;

const { t } = useI18n();

const mobile = useMobile();

const lowPower = useLowPowerDevice();

const holoModel = computed(() =>
  props.holo?.url
    ? { path: props.holo.url, size: props.holo.size ?? undefined }
    : undefined,
);

// three.js still crashes phones, and the inline preview cannot ask before
// loading a holo too large for the device, so both keep the picture.
const holoVisible = computed(
  () =>
    !!holoModel.value &&
    !mobile.value &&
    !(
      lowPower.value && (holoModel.value.size ?? 0) > LOW_POWER_HOLO_SIZE_LIMIT
    ),
);

const viewer = ref<{ enableFullscreen: () => void }>();

// Without WebGL or a holo that loads, the picture beats the viewer's notice.
const holoFailed = ref(false);

watch(
  () => props.holo?.url,
  () => {
    holoFailed.value = false;
  },
);
</script>

<template>
  <div
    v-if="holoVisible && holoModel && !(holoFailed && image?.largeUrl)"
    class="item-hero item-hero--holo"
    :data-test="`${testId}-holo`"
  >
    <HoloViewer
      ref="viewer"
      :models="[holoModel]"
      :controllable="false"
      :azimuth="HOLO_AZIMUTH"
      inline
      @unavailable="holoFailed = true"
    />
    <Btn
      class="item-hero__fullscreen"
      :aria-label="t('actions.vehicleOverview.fullscreenHolo')"
      v-tooltip="t('actions.vehicleOverview.fullscreenHolo')"
      :data-test="`${testId}-fullscreen`"
      @click="viewer?.enableFullscreen()"
    >
      <i class="fa-light fa-expand" />
    </Btn>
  </div>
  <img
    v-else-if="image?.largeUrl"
    class="item-hero item-hero__image"
    :src="image.largeUrl"
    :alt="name"
    :data-test="testId"
  />
</template>

<style lang="scss" scoped>
@import "index";
</style>
