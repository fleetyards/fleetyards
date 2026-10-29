<script lang="ts">
export default {
  name: "ItemHero",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { type MediaFile } from "@/services/fyApi";
import { useItemHolo } from "@/frontend/composables/useItemHolo";
import { LOW_POWER_HOLO_SIZE_LIMIT } from "@/shared/components/HoloViewer/limits";
import { useI18n } from "@/shared/composables/useI18n";
import { useLowPowerDevice } from "@/shared/composables/useLowPowerDevice";
import { useMobile } from "@/shared/composables/useMobile";
import { type RouteLocationNamedRaw } from "vue-router";

type Props = {
  image?: MediaFile | null;
  holo?: MediaFile | null;
  holoTextured?: MediaFile | null;
  viewerRoute: RouteLocationNamedRaw;
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

// The inline preview cannot ask before loading a holo too large for the
// device, so such a device is not offered the textured one.
const route = useRoute();

// Back from full screen, it shows the holo that was left on there.
const { texturedHolo, texturedHoloAvailable, toggleTexturedHolo, holoModel } =
  useItemHolo(() => ({ holo: props.holo, holoTextured: props.holoTextured }), {
    textured: route.query.textured === "1",
    canLoad: (file) =>
      !(lowPower.value && (file.size ?? 0) > LOW_POWER_HOLO_SIZE_LIMIT),
  });

watch(
  () => props.holo?.url,
  () => {
    texturedHolo.value = false;
  },
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

// Full screen is a page of its own, as on the ship page, so the inline viewer
// keeps its own camera and the textured choice travels in the link.
const fullscreenRoute = computed<RouteLocationNamedRaw>(() => ({
  ...props.viewerRoute,
  query: holoModel.value?.textured ? { textured: "1" } : undefined,
}));

// Without WebGL or a holo that loads, the picture beats the viewer's notice.
const holoFailed = ref(false);

// A textured holo that will not draw falls back to the plain one, which keeps
// the switch back to it. The viewer is keyed by the holo, so the plain one gets
// a fresh context and a late error from the textured one never arrives.
const holoUnavailable = () => {
  if (holoModel.value?.textured) {
    texturedHolo.value = false;
  } else {
    holoFailed.value = true;
  }
};

watch(
  () => holoModel.value?.path,
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
      :key="holoModel.path"
      :models="[holoModel]"
      :controllable="false"
      :azimuth="HOLO_AZIMUTH"
      inline
      @unavailable="holoUnavailable"
    />
    <div class="item-hero__actions">
      <Btn
        v-if="texturedHoloAvailable"
        :active="texturedHolo"
        :aria-label="t('labels.texturedHolo')"
        v-tooltip="t('labels.texturedHolo')"
        :data-test="`${testId}-holo-textured`"
        @click="toggleTexturedHolo"
      >
        <i class="fa-duotone fa-palette" />
      </Btn>
      <Btn
        :aria-label="t('actions.vehicleOverview.fullscreenHolo')"
        v-tooltip="t('actions.vehicleOverview.fullscreenHolo')"
        :data-test="`${testId}-fullscreen`"
        :to="fullscreenRoute"
      >
        <i class="fa-light fa-expand" />
      </Btn>
    </div>
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
