<script lang="ts">
export default {
  name: "HoloViewer2",
};
</script>

<script lang="ts" setup>
import Loader from "@/shared/components/Loader/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { type Vector3 } from "three";
import { useI18n } from "@/shared/composables/useI18n";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { TresCanvas } from "@tresjs/core";
import { OrbitControls } from "@tresjs/cientos";
import Model from "./Model/index.vue";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

type Props = {
  holo: string;
  colored?: boolean;
  controllable?: boolean;
  inline?: boolean;
  fullscreen?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  colored: false,
  controllable: true,
  inline: false,
  fullscreen: false,
});

const { displayAlert } = useAppNotifications();

const internalFullscreen = ref(props.fullscreen);

const enableFullscreen = () => {
  internalFullscreen.value = true;
};

const disableFullscreen = () => {
  internalFullscreen.value = false;
};

const { t } = useI18n();

const modelColor = ref("#428bca");

const autoRotateSpeed = 0.5;

const loading = ref(false);

const progress = ref(0);

const debug = ref(false);

const autoRotate = ref(true);

const zoom = ref(false);

const color = ref(false);

const autoRotateTooltip = computed(() => {
  if (autoRotate.value) {
    return t("actions.holoViewer.autoRotate.disable");
  }

  return t("actions.holoViewer.autoRotate.enable");
});

const zoomTooltip = computed(() => {
  if (zoom.value) {
    return t("actions.holoViewer.zoom.disable");
  }

  return t("actions.holoViewer.zoom.enable");
});

const colorTooltip = computed(() => {
  if (color.value) {
    return t("actions.holoViewer.color.disable");
  }

  return t("actions.holoViewer.color.enable");
});

onMounted(async () => {
  loading.value = true;
  progress.value = 0;
});

const toggleZoom = () => {
  zoom.value = !zoom.value;
};

const toggleColor = () => {
  color.value = !color.value;
};

const toggleAutoRotate = () => {
  autoRotate.value = !autoRotate.value;
};

const cameraPosition = ref<[x: number, y: number, z: number]>([11, 11, 11]);

const cameraArgs = ref<
  [fov: number, aspect: number, near: number, far: number]
>([35, window.innerWidth / window.innerHeight, 0.1, 1000]);

const cameraAngle = computed(() => {
  return props.inline ? 15 : 30;
});

const handleModelLoaded = (size: Vector3) => {
  loading.value = false;

  const distance =
    size.x / (2 * Math.tan((cameraArgs.value[0] * Math.PI) / 360));

  cameraPosition.value = [0, cameraAngle.value, distance];
};

const handleModelError = (error: unknown) => {
  loading.value = false;

  console.error(error);

  displayAlert({
    text: t("messages.holoViewer.modelLoader.failure"),
  });
};

const handleModelProgress = (loaded: number, total: number) => {
  progress.value = (loaded / total) * 100;
};

defineExpose({
  fullscreen: internalFullscreen,
  enableFullscreen,
  disableFullscreen,
});
</script>

<template>
  <div
    class="holo-viewer"
    :class="{
      'holo-viewer--inline': inline && !internalFullscreen,
      'holo-viewer--fullscreen': internalFullscreen,
    }"
  >
    <Btn
      v-if="internalFullscreen"
      variant="link"
      class="holo-viewer__close"
      @click.prevent.stop="disableFullscreen"
    >
      <i class="fal fa-times" />
    </Btn>
    <BtnGroup
      v-if="controllable || internalFullscreen"
      class="holo-viewer__actions"
      inline
    >
      <Btn
        v-tooltip="autoRotateTooltip"
        :size="BtnSizesEnum.SMALL"
        :active="autoRotate"
        inline
        @click="toggleAutoRotate"
      >
        <i class="fal fa-planet-ringed" />
      </Btn>
      <Btn
        v-tooltip="zoomTooltip"
        :size="BtnSizesEnum.SMALL"
        :active="zoom"
        inline
        @click="toggleZoom"
      >
        <i class="fal fa-search-plus" />
      </Btn>
      <Btn
        v-if="colored"
        v-tooltip="colorTooltip"
        :size="BtnSizesEnum.SMALL"
        :active="color"
        inline
        @click="toggleColor"
      >
        <i class="fad fa-fill-drip" />
      </Btn>
    </BtnGroup>

    <Loader v-if="loading" :loading="loading" :progress="progress" />
    <input v-if="debug" v-model="modelColor" type="color" />
    <TresCanvas preset="realistic">
      <TresPerspectiveCamera :position="cameraPosition" :args="cameraArgs">
        <TresDirectionalLight cast-shadow />
      </TresPerspectiveCamera>
      <OrbitControls
        :auto-rotate="autoRotate"
        :auto-rotate-speed="autoRotateSpeed"
        :enable-rotate="controllable || internalFullscreen"
        :enable-zoom="zoom"
        :zoom-speed="0.5"
        :min-distance="50"
        :max-distance="250"
        enable-damping
        :damping-factor="0.25"
        :enable-pan="false"
      />
      <Suspense>
        <Model
          :path="holo"
          :color="modelColor"
          @loaded="handleModelLoaded"
          @error="handleModelError"
          @progress="handleModelProgress"
        />
      </Suspense>
    </TresCanvas>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
