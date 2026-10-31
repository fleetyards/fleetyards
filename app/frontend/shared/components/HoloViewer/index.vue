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
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import {
  ACESFilmicToneMapping,
  type Camera,
  Box3,
  type Mesh,
  NeutralToneMapping,
  type Object3D,
  type PerspectiveCamera,
  Sphere,
  Vector3,
} from "three";
import { useI18n } from "@/shared/composables/useI18n";

import { TresCanvas } from "@tresjs/core";
import { webglAvailable } from "@/shared/utils/Webgl";
import { OrbitControls, TransformControls, Grid, Stars } from "@tresjs/cientos";
import Model from "./Model/index.vue";
import RoomLighting from "./RoomLighting/index.vue";
import Skybox from "./Skybox/index.vue";
import pyroNebula from "@/images/skyboxes/pyro_nebula_4k.webp";
import pyroNebulaSmall from "@/images/skyboxes/pyro_nebula_2k.webp";
import stantonNebula from "@/images/skyboxes/stanton_nebula_spherical_4k.webp";
import stantonNebulaSmall from "@/images/skyboxes/stanton_nebula_spherical_2k.webp";
import crusaderNebula from "@/images/skyboxes/stanton_crusader_nebula_4k.webp";
import crusaderNebulaSmall from "@/images/skyboxes/stanton_crusader_nebula_2k.webp";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useLowPowerDevice } from "@/shared/composables/useLowPowerDevice";
import { LOW_POWER_HOLO_SIZE_LIMIT } from "@/shared/components/HoloViewer/limits";
import { type HoloMount } from "@/shared/components/HoloViewer/mounts";

export type HoloModel = {
  path: string;
  length?: number;
  // Bytes, where the file is known: a phone asks before loading a large one.
  size?: number;
  // Painted and animated: drawn with its own materials, not the holo's.
  textured?: boolean;
  // A textured holo's paint: the base-colour map its body is drawn with in
  // place of the export's own, and the occlusion/roughness/metallic map that
  // goes with it.
  paint?: string;
  paintOrm?: string;
  // Parts drawn on the holo's ports, in its own frame.
  mounts?: HoloMount[];
};

type Props = {
  models: HoloModel[];
  colored?: boolean;
  controllable?: boolean;
  autoRotate?: boolean;
  inline?: boolean;
  fullscreen?: boolean;
  grid?: boolean;
  // Offer the backdrops to pick from: the full screen viewer's.
  backgrounds?: boolean;
  zoomable?: boolean;
  panable?: boolean;
  // Where the camera starts around the model, in degrees from +Z. Holos keep
  // the game's entity frame, a ship's nose towards -Z, so the default starts
  // on its side.
  azimuth?: number;
  // How far above the model the camera starts, in degrees. Without it the
  // camera stays low, under a cap that keeps every holo framed alike.
  elevation?: number;
  // Framed so the whole model is in view whatever its shape and the frame's:
  // its bounding sphere fitted to both fields of view, from the elevation's
  // direction.
  contain?: boolean;
  // See-through, with the mesh's wireframe drawn over it.
  hologram?: boolean;
  // Drawn only when something changes rather than every frame, for a holo
  // that mostly stands still. Set once: the renderer cannot switch modes once
  // it runs.
  onDemand?: boolean;
  // Mounted parts answer the pointer: hovered and clicked by their mount's id.
  pickable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  colored: false,
  controllable: true,
  autoRotate: true,
  inline: false,
  fullscreen: false,
  grid: false,
  backgrounds: false,
  panable: false,
  zoomable: false,
  azimuth: -90,
  elevation: undefined,
  contain: false,
  hologram: false,
  onDemand: false,
  pickable: false,
});

// Nothing will be drawn: no WebGL, or a holo that would not load. A caller with
// a picture to show instead can switch to it.
// `loaded` once a model is on screen, for a caller holding a picture until then.
const emit = defineEmits<{
  unavailable: [];
  loaded: [];
  mountSelect: [id: string];
  mountPoint: [id: string | undefined];
}>();

const { displayAlert } = useAppNotifications();

const lowPower = useLowPowerDevice();

const webglSupported = ref(true);

// What was agreed to, in bytes: anything up to it -- the other pose of the same
// ship, usually -- loads without asking again, and anything larger asks anew.
const confirmedSize = ref(0);

// Drawn with its own colours, which the tone mapping keeps as they are rather
// than pushing the dark ones towards black.
const textured = computed(() => props.models.some((model) => model.textured));

const totalSize = computed(() =>
  props.models.reduce((sum, model) => sum + (model.size ?? 0), 0),
);

const awaitingConfirmation = computed(
  () =>
    lowPower.value &&
    totalSize.value > LOW_POWER_HOLO_SIZE_LIMIT &&
    totalSize.value > confirmedSize.value,
);

const totalSizeMb = computed(() => Math.round(totalSize.value / 1_000_000));

onMounted(() => {
  webglSupported.value = webglAvailable();
});

watch(webglSupported, (supported) => {
  if (!supported) emit("unavailable");
});

// THREE throws while constructing the renderer, which TresCanvas's `on-error`
// never sees: it comes out through Vue's error handler instead, which is how a
// missing context got reported as an application error rather than showing the
// fallback this component already has. Swallowing it is scoped to this
// boundary, and a 3D viewer is the right place to decide that WebGL is absent.
onErrorCaptured((error) => {
  if (!(error instanceof Error) || !error.message.includes("WebGL")) {
    return true;
  }

  webglSupported.value = false;

  return false;
});

const dpr = computed(() =>
  lowPower.value
    ? Math.min(window.devicePixelRatio, 1.5)
    : window.devicePixelRatio,
);

const powerPreference = computed<WebGLPowerPreference>(() =>
  lowPower.value ? "low-power" : "default",
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

// A swapped path is a fresh download -- the ship page switching between the
// flying and the landed holo is the everyday case -- and the old mesh stays on
// screen while it runs. Without this the viewer sat there looking finished, with
// the progress bar still reading 100% from the file before it.
watch(
  () => props.models.map((model) => model.path).join(","),
  () => {
    loading.value = true;
    progress.value = 0;
  },
);

const toggleZoom = () => {
  zoom.value = !zoom.value;
};

const BACKGROUNDS = [
  "dark",
  "space",
  "stanton",
  "crusader",
  "pyro",
  "light",
] as const;

type Background = (typeof BACKGROUNDS)[number];

const BACKGROUND_ICONS: Record<Background, string> = {
  dark: "fa-light fa-moon",
  space: "fa-light fa-stars",
  stanton: "fa-light fa-galaxy",
  crusader: "fa-light fa-planet-moon",
  pyro: "fa-light fa-fire",
  light: "fa-light fa-sun",
};

// Panoramas from the game's own skies, the smaller cut on a low power device.
const SKYBOXES: Partial<Record<Background, { src: string; small: string }>> = {
  stanton: { src: stantonNebula, small: stantonNebulaSmall },
  crusader: { src: crusaderNebula, small: crusaderNebulaSmall },
  pyro: { src: pyroNebula, small: pyroNebulaSmall },
};

const background = ref<Background>("dark");

const backgroundName = (name: Background) =>
  t(`labels.holoViewer.background.${name}`);

const skybox = computed(() => {
  if (!props.backgrounds) return undefined;

  const sky = SKYBOXES[background.value];

  return sky && (lowPower.value ? sky.small : sky.src);
});

// Hidden only: the model stays scaled and set down as it is on the grid.
const gridVisible = ref(true);

const gridTooltip = computed(() =>
  gridVisible.value
    ? t("actions.holoViewer.grid.disable")
    : t("actions.holoViewer.grid.enable"),
);

const toggleGrid = () => {
  gridVisible.value = !gridVisible.value;
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
const lightPosition = ref<[x: number, y: number, z: number]>([100, 100, 100]);

// The renderer's mode, fixed as it mounts: switched while running from on
// demand to always, it never draws again.
const renderMode = props.onDemand ? "on-demand" : "always";

const canvas = ref<{
  context?: { renderer?: { invalidate: () => void } };
}>();

// The orbit controls move the camera without asking for a frame. Each change
// asks for the next one, so a drag, its easing out and an auto-rotation all
// keep drawing, and a camera at rest draws nothing.
const handleControlsChange = (controls: { object: Camera }) => {
  const { x, y, z } = controls.object.position;
  lightPosition.value = [x, y, z];

  const camera = controls.object as PerspectiveCamera;
  const near = nearPlaneFor(camera.position.length());
  if (camera.isPerspectiveCamera && camera.near !== near) {
    camera.near = near;
    camera.updateProjectionMatrix();
  }

  canvas.value?.context?.renderer?.invalidate();
};

const fitDistance = ref(100);
const modelMaxDimension = ref(100);

// How far from the origin the furthest loaded model reaches: the models after
// the first are stacked above it.
const modelReach = ref(0);

const MIN_NEAR = 0.1;

// Depth precision falls with the square of the distance over the near plane,
// and a textured export's hull carries paint layers stacked a fraction of a
// millimetre apart: with the near plane fixed at 0.1 they fight at any
// distance that fits the ship. Half the gap to the models' bounding sphere
// keeps the near plane clear of them, while zoomed in it falls back to 0.1.
const nearPlaneFor = (cameraDistance: number) =>
  Math.max(MIN_NEAR, (cameraDistance - modelReach.value) / 2);

const maxZoomDistance = computed(() => Math.max(250, fitDistance.value * 3));

const starsVisible = computed(
  () => props.backgrounds && background.value === "space",
);

const STARS_RADIUS = 1.5;
const STARS_DEPTH = 1;

// The star shell's far side, seen from the camera zoomed all the way out: past
// the model's own far plane on anything larger than a fighter, which clipped
// every star.
const starsReach = computed(
  () => maxZoomDistance.value * (1 + STARS_RADIUS + STARS_DEPTH) * 1.05,
);

const cameraArgs = computed<
  [fov: number, aspect: number, near: number, far: number]
>(() => [
  35,
  innerWidth.value / innerHeight.value,
  nearPlaneFor(fitDistance.value),
  Math.max(
    1000,
    fitDistance.value * 4 + modelMaxDimension.value,
    starsVisible.value ? starsReach.value : 0,
  ),
]);

const cameraHeight = computed(() => (props.inline ? 15 : 30));

// The steepest the camera is allowed to look down, in degrees. The height
// above is in world units, which only reads as a shallow angle while every
// export is about the same size -- a normalised one is around 100 units
// across and fits at 145 away, so 30 above it is 12 degrees. An export
// uploaded untransformed, so its bounding box can be measured, is whatever
// size the game file is: the Cyclone is 5.7 units across and fits at 9 away,
// where the same 30 is 73 degrees, looking down on the roof.
//
// A cap rather than a fixed angle: anything already at or below it keeps the
// exact framing it has, which is every holo uploaded before the change.
const maxCameraElevation = computed(() => (props.inline ? 6 : 12));

const gridCellSize = computed(() =>
  Math.max(0.6, modelMaxDimension.value / 100),
);
const gridSectionSize = computed(() => gridCellSize.value * 4);
const gridPosition = computed<[number, number, number]>(() => [
  0,
  -modelMaxDimension.value * 0.55,
  0,
]);
const gridFadeDistance = computed(() =>
  Math.max(100, modelMaxDimension.value * 2),
);

const handleModelLoaded = (size: Vector3, scene: Object3D) => {
  // if (props.grid) {
  //   currentModel.value = scene;
  // }

  loading.value = false;
  emit("loaded");

  const bounds = new Box3()
    .setFromObject(scene)
    .getBoundingSphere(new Sphere());
  modelReach.value = Math.max(
    modelReach.value,
    bounds.center.length() + bounds.radius,
  );

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

  const azimuth = (props.azimuth * Math.PI) / 180;

  if (props.contain) {
    // The frame as it is now: the cached aspect is the one it mounted with.
    const frame = holoViewer.value;
    const frameAspect =
      frame && frame.clientHeight ? frame.clientWidth / frame.clientHeight : 1;
    const elevation = ((props.elevation ?? 0) * Math.PI) / 180;
    const tanVertical = Math.tan(fovRadians / 2);
    const tanHorizontal = tanVertical * frameAspect;

    // The camera's axes, looking at the centred model from the pose.
    const toCamera = new Vector3(
      Math.sin(azimuth) * Math.cos(elevation),
      Math.sin(elevation),
      Math.cos(azimuth) * Math.cos(elevation),
    );
    const right = new Vector3(0, 1, 0).cross(toCamera).normalize();
    const up = toCamera.clone().cross(right);

    // The nearest distance at which every point of the model is still in
    // frame. Its box would do, but from an angle
    // the box's far corners stand well clear of the ship itself. A sample of
    // each mesh's points is enough to find the silhouette's edges.
    let reach = 0;
    const point = new Vector3();
    scene.updateMatrixWorld(true);
    scene.traverse((node) => {
      const mesh = node as Mesh;
      const positions = mesh.isMesh
        ? mesh.geometry.getAttribute("position")
        : undefined;
      if (!positions) return;

      const step = Math.max(1, Math.floor(positions.count / 2000));
      for (let index = 0; index < positions.count; index += step) {
        point.fromBufferAttribute(positions, index);
        point.applyMatrix4(mesh.matrixWorld);

        const depth = point.dot(toCamera);
        reach = Math.max(
          reach,
          depth + Math.abs(point.dot(right)) / tanHorizontal,
          depth + Math.abs(point.dot(up)) / tanVertical,
        );
      }
    });
    // Room around it: a frame rarely shows its edges whole, the editor's fades
    // in from the left under the controls.
    reach *= 1.35;

    fitDistance.value = reach;
    modelMaxDimension.value = Math.max(size.x, size.y, size.z);

    const position: [number, number, number] = [
      Math.sin(azimuth) * Math.cos(elevation) * reach,
      Math.sin(elevation) * reach,
      Math.cos(azimuth) * Math.cos(elevation) * reach,
    ];

    cameraPosition.value = position;
    lightPosition.value = position;

    return;
  }

  const distance =
    dominantSize / Math.tan(fovRadians / (aspect > 2 ? aspect * 0.75 : aspect));

  fitDistance.value = distance;
  modelMaxDimension.value = Math.max(size.x, size.y, size.z);

  const height =
    props.elevation === undefined
      ? Math.min(
          cameraHeight.value,
          Math.tan((maxCameraElevation.value * Math.PI) / 180) * distance,
        )
      : Math.tan((props.elevation * Math.PI) / 180) * distance;

  const position: [number, number, number] = [
    Math.sin(azimuth) * distance,
    height,
    Math.cos(azimuth) * distance,
  ];

  cameraPosition.value = position;
  lightPosition.value = position;
};

const handleRenderError = (error: Error) => {
  console.error("HoloViewer render error:", error);
  webglSupported.value = false;
};

const handleModelError = (error: unknown) => {
  loading.value = false;
  emit("unavailable");

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
      [`holo-viewer--${background}`]: backgrounds,
    }"
  >
    <Btn
      v-if="internalFullscreen"
      class="holo-viewer__close"
      @click.prevent.stop="disableFullscreen"
      variant="bare"
    >
      <i class="fa-light fa-times" />
    </Btn>
    <BtnGroup
      v-if="controllable || internalFullscreen"
      class="holo-viewer__actions"
    >
      <Btn
        v-tooltip="autoRotateTooltip"
        :active="internalAutoRotate"
        @click="toggleAutoRotate"
      >
        <i class="fa-light fa-planet-ringed" />
      </Btn>
      <Btn v-tooltip="zoomTooltip" :active="zoom" @click="toggleZoom">
        <i class="fa-light fa-search-plus" />
      </Btn>
      <Btn
        v-if="colored"
        v-tooltip="colorTooltip"
        :active="color"
        @click="toggleColor"
      >
        <i class="fa-duotone fa-fill-drip" />
      </Btn>
      <Btn
        v-if="grid"
        v-tooltip="gridTooltip"
        :active="gridVisible"
        data-test="holo-viewer-grid"
        @click="toggleGrid"
      >
        <i class="fa-light fa-grid" />
      </Btn>
      <BtnDropdown
        v-if="backgrounds"
        expand-top
        expand-left
        data-test="holo-viewer-background"
      >
        <template #label>
          <i :class="BACKGROUND_ICONS[background]" />
          <span>{{ backgroundName(background) }}</span>
          <i class="fa-light fa-chevron-up" />
        </template>
        <Btn
          v-for="option in BACKGROUNDS"
          :key="option"
          :active="background === option"
          :data-test="`holo-viewer-background-${option}`"
          @click="background = option"
        >
          <i :class="BACKGROUND_ICONS[option]" />
          {{ backgroundName(option) }}
        </Btn>
      </BtnDropdown>
    </BtnGroup>

    <Loader
      v-if="loading && webglSupported && !awaitingConfirmation"
      :loading="loading"
      :progress="progress"
    />
    <input v-if="debug" v-model="modelColor" type="color" />
    <div v-if="!webglSupported" class="holo-viewer__fallback">
      <i class="fa-light fa-cube" />
      <p>{{ t("messages.holoViewer.webglNotSupported") }}</p>
    </div>
    <div
      v-else-if="awaitingConfirmation"
      class="holo-viewer__fallback"
      data-test="holo-viewer-too-large"
    >
      <i class="fa-light fa-cube" />
      <p>
        {{ t("messages.holoViewer.tooLarge", { size: totalSizeMb }) }}
      </p>
      <Btn
        data-test="holo-viewer-load-anyway"
        @click="confirmedSize = totalSize"
      >
        {{ t("actions.holoViewer.loadAnyway") }}
      </Btn>
    </div>
    <TresCanvas
      v-else
      :clear-alpha="0"
      :shadows="!lowPower"
      :dpr="dpr"
      :power-preference="powerPreference"
      :antialias="!lowPower"
      ref="canvas"
      :render-mode="renderMode"
      :tone-mapping="textured ? NeutralToneMapping : ACESFilmicToneMapping"
      alpha
      :on-error="handleRenderError"
    >
      <TresPerspectiveCamera :position="cameraPosition" :args="cameraArgs" />
      <TresDirectionalLight
        :position="lightPosition"
        :intensity="textured ? 1.5 : 2"
        :cast-shadow="!lowPower"
      />
      <RoomLighting v-if="textured" />
      <TresAmbientLight v-else :intensity="lowPower ? 0.8 : 0.5" />
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
        @change="handleControlsChange"
      />
      <TransformControls v-if="currentModel" :object="currentModel" />
      <!-- Out past the camera's widest zoom, and sized with it, so a ship and a
           part sit in the same sky. -->
      <Stars
        v-if="starsVisible"
        :radius="maxZoomDistance * STARS_RADIUS"
        :depth="maxZoomDistance * STARS_DEPTH"
        :count="4000"
        :size="maxZoomDistance / 150"
      />
      <Skybox v-if="skybox" :src="skybox" />
      <Grid
        v-if="grid && gridVisible"
        :args="[10, 10]"
        :position="gridPosition"
        cell-color="#82dbc5"
        :cell-size="gridCellSize"
        :cell-thickness="0.5"
        section-color="#fbb03b"
        :section-size="gridSectionSize"
        :section-thickness="1.3"
        :infinite-grid="true"
        :fade-from="0"
        :fade-distance="gridFadeDistance"
        :fade-strength="1"
      />
      <Suspense>
        <Model
          v-for="model in models"
          :key="model.path"
          :model="model"
          :color="modelColor"
          :on-grid="grid"
          :mobile="lowPower"
          :hologram="hologram"
          :pickable="pickable"
          :offsetModel="models[models.indexOf(model) - 1]"
          @loaded="handleModelLoaded"
          @error="handleModelError"
          @progress="handleModelProgress"
          @mount-select="emit('mountSelect', $event)"
          @mount-point="emit('mountPoint', $event)"
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
