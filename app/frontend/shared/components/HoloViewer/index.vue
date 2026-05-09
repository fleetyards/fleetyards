<!-- eslint-disable import/no-self-import -->
<script lang="ts">
export default {
  name: "HoloViewer",
};
</script>

<script lang="ts" setup>
import Loader from "@/shared/components/Loader/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { type Mesh, type Object3D, type Vector3 } from "three";
import { useI18n } from "@/shared/composables/useI18n";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { TresCanvas } from "@tresjs/core";
import { OrbitControls, TransformControls, Grid } from "@tresjs/cientos";
import Model from "./Model/index.vue";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useMobile } from "@/shared/composables/useMobile";

export type HoloModel = {
  path: string;
  length?: number;
};

type Props = {
  models: HoloModel[];
  colored?: boolean;
  controllable?: boolean;
  autoRotate?: boolean;
  inline?: boolean;
  fullscreen?: boolean;
  grid?: boolean;
  zoomable?: boolean;
  panable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  colored: false,
  controllable: true,
  autoRotate: true,
  inline: false,
  fullscreen: false,
  grid: false,
  panable: false,
  zoomable: false,
});

const { displayAlert } = useAppNotifications();

const mobile = useMobile();

const webglSupported = ref(true);

onMounted(() => {
  try {
    const canvas = document.createElement("canvas");
    const gl = canvas.getContext("webgl2") || canvas.getContext("webgl");
    if (!gl) {
      webglSupported.value = false;
    }
  } catch {
    webglSupported.value = false;
  }
});

const dpr = computed(() =>
  mobile.value
    ? Math.min(window.devicePixelRatio, 1.5)
    : window.devicePixelRatio,
);

const powerPreference = computed<WebGLPowerPreference>(() =>
  mobile.value ? "low-power" : "default",
);

const internalFullscreen = ref(props.fullscreen);

const enableFullscreen = () => {
  internalFullscreen.value = true;
};

const disableFullscreen = () => {
  internalFullscreen.value = false;
};

const { t } = useI18n();

const holoViewer = ref<HTMLElement>();

const modelColor = ref("#428bca");

const autoRotateSpeed = 0.5;

const loading = ref(false);

const progress = ref(0);

const debug = ref(false);

const internalAutoRotate = ref(props.autoRotate);

const zoom = ref(props.zoomable);

const color = ref(false);

const autoRotateTooltip = computed(() => {
  if (internalAutoRotate.value) {
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

onMounted(() => {
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
  internalAutoRotate.value = !internalAutoRotate.value;
};

const innerWidth = computed(() => {
  if (!internalFullscreen.value && holoViewer.value) {
    return holoViewer.value.clientWidth;
  }

  return window.innerWidth;
});

const innerHeight = computed(() => {
  if (!internalFullscreen.value && holoViewer.value) {
    return holoViewer.value.clientHeight;
  }

  return window.innerHeight;
});

const cameraPosition = ref<[x: number, y: number, z: number]>([100, 100, 100]);

const fitDistance = ref(100);
const modelMaxDimension = ref(100);

const cameraArgs = computed<
  [fov: number, aspect: number, near: number, far: number]
>(() => [
  35,
  innerWidth.value / innerHeight.value,
  0.1,
  Math.max(1000, fitDistance.value * 4 + modelMaxDimension.value),
]);

const maxZoomDistance = computed(() => Math.max(250, fitDistance.value * 3));

const cameraAngle = computed(() => {
  return props.inline ? 15 : 30;
});

const handleModelLoaded = (size: Vector3, _scene: Mesh) => {
  // if (props.grid) {
  //   currentModel.value = scene;
  // }

  loading.value = false;

  // Get canvas aspect ratio
  const aspect = cameraArgs.value[1]; // width / height

  // Calculate which dimension dominates based on canvas aspect ratio
  // For wide screens (aspect > 1), horizontal dimension matters more
  // For tall screens (aspect < 1), vertical dimension matters more
  const horizontalSize = Math.max(size.x, size.z); // Model's horizontal extent
  const verticalSize = size.y; // Model's vertical extent

  // Adjust effective size based on aspect ratio
  // If canvas is wide, we can afford a wider model
  // If canvas is tall/square, vertical size becomes limiting factor
  const effectiveHorizontalSize = horizontalSize / Math.max(aspect, 1);
  const effectiveVerticalSize = verticalSize / Math.min(aspect, 1);

  // Use the larger of the two to ensure model fits
  const dominantSize = Math.max(effectiveHorizontalSize, effectiveVerticalSize);

  // Calculate distance using field of view
  const fovRadians = (cameraArgs.value[0] * Math.PI) / 180;

  const distance =
    dominantSize / Math.tan(fovRadians / (aspect > 2 ? aspect * 0.75 : aspect));

  fitDistance.value = distance;
  modelMaxDimension.value = Math.max(size.x, size.y, size.z);

  cameraPosition.value = [0, cameraAngle.value, distance];
};

const handleRenderError = (error: Error) => {
  console.error("HoloViewer render error:", error);
  webglSupported.value = false;
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

const currentModel = ref<Object3D>();

const _traverseEventObjects = (object: Mesh): Mesh => {
  if (object.parent && object.parent.type !== "Scene") {
    return _traverseEventObjects(object.parent as Mesh);
  }

  return object;
};

// const handleModelClick = (event: ModelClickEvent) => {
//   if (!event.object || !props.grid) {
//     return;
//   }

//   currentModel.value = traverseEventObjects(event.object);
// };

defineExpose({
  fullscreen: internalFullscreen,
  enableFullscreen,
  disableFullscreen,
});
</script>

<template>
  <div
    class="holo-viewer"
    ref="holoViewer"
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
      <i class="fa-light fa-times" />
    </Btn>
    <BtnGroup
      v-if="controllable || internalFullscreen"
      class="holo-viewer__actions"
      inline
    >
      <Btn
        v-tooltip="autoRotateTooltip"
        :size="BtnSizesEnum.SMALL"
        :active="internalAutoRotate"
        inline
        @click="toggleAutoRotate"
      >
        <i class="fa-light fa-planet-ringed" />
      </Btn>
      <Btn
        v-tooltip="zoomTooltip"
        :size="BtnSizesEnum.SMALL"
        :active="zoom"
        inline
        @click="toggleZoom"
      >
        <i class="fa-light fa-search-plus" />
      </Btn>
      <Btn
        v-if="colored"
        v-tooltip="colorTooltip"
        :size="BtnSizesEnum.SMALL"
        :active="color"
        inline
        @click="toggleColor"
      >
        <i class="fa-duotone fa-fill-drip" />
      </Btn>
    </BtnGroup>

    <Loader
      v-if="loading && webglSupported"
      :loading="loading"
      :progress="progress"
    />
    <input v-if="debug" v-model="modelColor" type="color" />
    <div v-if="!webglSupported" class="holo-viewer__fallback">
      <i class="fa-light fa-cube" />
      <p>{{ t("messages.holoViewer.webglNotSupported") }}</p>
    </div>
    <TresCanvas
      v-else
      :clear-alpha="0"
      :shadows="!mobile"
      :dpr="dpr"
      :power-preference="powerPreference"
      alpha
      :on-error="handleRenderError"
    >
      <TresPerspectiveCamera :position="cameraPosition" :args="cameraArgs">
        <TresDirectionalLight :intensity="2" :cast-shadow="!mobile" />
        <TresAmbientLight :intensity="mobile ? 0.8 : 0.5" />
      </TresPerspectiveCamera>
      <OrbitControls
        :auto-rotate="internalAutoRotate"
        :auto-rotate-speed="autoRotateSpeed"
        :enable-rotate="controllable || internalFullscreen"
        :enable-zoom="zoom"
        :zoom-speed="0.5"
        :min-distance="-50"
        :max-distance="maxZoomDistance"
        enable-damping
        :damping-factor="0.25"
        :enable-pan="panable"
        make-default
      />
      <TransformControls v-if="currentModel" :object="currentModel" />
      <Grid
        v-if="grid"
        :args="[10, 10]"
        :position="[0, -20, 0]"
        cell-color="#82dbc5"
        :cell-size="0.6"
        :cell-thickness="0.5"
        section-color="#fbb03b"
        :section-size="2"
        :section-thickness="1.3"
        :infinite-grid="true"
        :fade-from="0"
        :fade-distance="100"
        :fade-strength="1"
      />
      <Suspense>
        <Model
          v-for="model in models"
          :model="model"
          :color="modelColor"
          :on-grid="grid"
          :mobile="mobile"
          :offsetModel="models[models.indexOf(model) - 1]"
          @loaded="handleModelLoaded"
          @error="handleModelError"
          @progress="handleModelProgress"
        />
        <template #fallback>
          <Loader :loading="true" :progress="progress" />
        </template>
      </Suspense>
    </TresCanvas>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
