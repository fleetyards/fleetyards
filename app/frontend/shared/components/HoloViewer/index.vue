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
import AppModalCloseBtn from "@/shared/components/AppModal/CloseBtn/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import {
  ACESFilmicToneMapping,
  type Camera,
  type Group,
  Box3,
  type Mesh,
  NeutralToneMapping,
  type Object3D,
  type PerspectiveCamera,
  type SkinnedMesh,
  Sphere,
  Vector3,
} from "three";
import { useI18n } from "@/shared/composables/useI18n";

import { TresCanvas } from "@tresjs/core";
import { useResizeObserver, useDebounceFn } from "@vueuse/core";
import WebglFallback from "@/shared/components/WebglFallback/index.vue";
import { useWebglSupport } from "@/shared/composables/useWebglSupport";
import { OrbitControls, TransformControls, Grid, Stars } from "@tresjs/cientos";
import Model from "./Model/index.vue";
import RoomLighting from "./RoomLighting/index.vue";
import Skybox from "./Skybox/index.vue";
import pyroNebula from "@/images/skyboxes/pyro_nebula_2k.webp";
import stantonNebula from "@/images/skyboxes/stanton_nebula_spherical_2k.webp";
import crusaderNebula from "@/images/skyboxes/stanton_crusader_nebula_2k.webp";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useLowPowerDevice } from "@/shared/composables/useLowPowerDevice";
import { LOW_POWER_HOLO_SIZE_LIMIT } from "@/shared/components/HoloViewer/limits";
import {
  type HoloMount,
  mountsSize,
  mountsTextured,
} from "@/shared/components/HoloViewer/mounts";
import {
  type HoloRig,
  rigSize,
  rigTextured,
} from "@/shared/components/HoloViewer/rig";
import {
  BACKDROP_RADIUS,
  backdropScale,
  buildBackdrop,
  disposeBackdrop,
} from "@/shared/components/HoloViewer/backdrop";

export type HoloModel = {
  path: string;
  length?: number;
  // Bytes, where the file is known: a phone asks before loading a large one.
  size?: number;
  // Painted and animated: drawn with its own materials, not the holo's.
  textured?: boolean;
  // A textured holo's paint: the base-colour map its body is drawn with in
  // place of the export's own, the occlusion/roughness/metallic map that goes
  // with it, and the stencil sheet of a paint with artwork of its own.
  paint?: string;
  paintOrm?: string;
  paintStencil?: string;
  // Parts drawn on the holo's ports, in its own frame.
  mounts?: HoloMount[];
  // Framed and centred with its parts rather than on its own: a figure whose
  // pieces all share one frame.
  frameMounts?: boolean;
  // A rigged body: worn pieces bound to its skeleton and posed by a clip.
  rig?: HoloRig;
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
  // Turned only about its upright axis, without zoom, until shown full
  // screen, where it orbits freely.
  turntable?: boolean;
  // Room left around a contained model, as a factor of its fitted distance.
  containPadding?: number;
  // Stood in a lit room with a glossy floor rather than in an empty frame.
  backdrop?: boolean;
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
  turntable: false,
  containPadding: 1.35,
  backdrop: false,
});

// Nothing will be drawn: no WebGL, or a holo that would not load. A caller with
// a picture to show instead can switch to it.
// `loaded` once a model is on screen, for a caller holding a picture until then.
const emit = defineEmits<{
  unavailable: [failed?: string];
  loaded: [];
  mountSelect: [id: string];
  mountPoint: [id: string | undefined];
  unplaced: [paths: string[]];
  fellBack: [paths: string[]];
}>();

const { displayAlert } = useAppNotifications();

const lowPower = useLowPowerDevice();

const { webglSupported } = useWebglSupport();

// What was agreed to, in bytes: anything up to it -- the other pose of the same
// ship, usually -- loads without asking again, and anything larger asks anew.
const confirmedSize = ref(0);

// Drawn with its own colours, which the tone mapping keeps as they are rather
// than pushing the dark ones towards black.
const textured = computed(() =>
  props.models.some(
    (model) =>
      model.textured || mountsTextured(model.mounts) || rigTextured(model.rig),
  ),
);

// A rigged figure that brings the game's own lights is lit by them alone,
// over a small ambient term.
const ownLighting = computed(() =>
  props.models.some((model) => !!model.rig?.lights?.length),
);

const totalSize = computed(() =>
  props.models.reduce(
    (sum, model) =>
      sum + (model.size ?? 0) + mountsSize(model.mounts) + rigSize(model.rig),
    0,
  ),
);

const awaitingConfirmation = computed(
  () =>
    lowPower.value &&
    totalSize.value > LOW_POWER_HOLO_SIZE_LIMIT &&
    totalSize.value > confirmedSize.value,
);

const totalSizeMb = computed(() => Math.round(totalSize.value / 1_000_000));

watch(
  webglSupported,
  (supported) => {
    if (!supported) emit("unavailable");
  },
  { immediate: true },
);

const dpr = computed(() =>
  lowPower.value
    ? Math.min(window.devicePixelRatio, 1.5)
    : window.devicePixelRatio,
);

const powerPreference = computed<WebGLPowerPreference>(() =>
  lowPower.value ? "low-power" : "default",
);

const internalFullscreen = ref(props.fullscreen);

const turntableLocked = computed(
  () => props.turntable && !internalFullscreen.value,
);

// Level with the camera's starting height, so the turntable keeps the view
// it opened on.
const turntablePolar = computed(
  () => Math.PI / 2 - ((props.elevation ?? 0) * Math.PI) / 180,
);

// A room has a floor: the camera stops level with the model's centre, above
// it, rather than orbiting under to where neither floor nor room draws.
const FLOOR_POLAR = Math.PI / 2;

const TURNTABLE_SIDES = 16;

const enableFullscreen = () => {
  internalFullscreen.value = true;
};

const disableFullscreen = () => {
  internalFullscreen.value = false;

  // Panned only full screen: back from it, the model is centred again.
  if (!props.panable && liveControls?.target) {
    liveControls.target.set(0, 0, 0);
    liveControls.update?.();
  }

  // A turntable has no zoom of its own: back from full screen, it returns
  // to the framing it opened on rather than wherever full screen left it.
  if (props.turntable) cameraPosition.value = [...cameraPosition.value];
};

const closeOnEscape = (event: KeyboardEvent) => {
  if (event.key === "Escape") disableFullscreen();
};

// Immediate, so a viewer that opens full screen listens from the start.
watch(
  internalFullscreen,
  (fullscreen) => {
    if (fullscreen) {
      window.addEventListener("keydown", closeOnEscape);
    } else {
      window.removeEventListener("keydown", closeOnEscape);
    }
  },
  { immediate: true },
);

onUnmounted(() => window.removeEventListener("keydown", closeOnEscape));

// Kept out of the model's scene, so framing measures the figure alone.
const backdrop = shallowRef<Group>();

// The room grown to the model alone; see `roomScale` for the camera's part.
const modelRoomScale = ref(1);

// The model arrives centred on the origin, so its feet are half its height
// below.
const placeBackdrop = (size: Vector3) => {
  if (!props.backdrop) return;

  if (backdrop.value) disposeBackdrop(backdrop.value);
  modelRoomScale.value = backdropScale(size);
  backdrop.value = buildBackdrop(-size.y / 2, {
    reflective: !lowPower.value,
  });
  backdrop.value.scale.setScalar(roomScale.value);
};

onUnmounted(() => {
  if (backdrop.value) disposeBackdrop(backdrop.value);
});

const { t } = useI18n();

const holoViewer = ref<HTMLElement>();

const modelColor = ref("#428bca");

const autoRotateSpeed = 0.5;

const loading = ref(false);

// The model is loaded, but parts, a character or a paint are still coming in.
const busy = ref(false);

const progress = ref(0);

const debug = ref(false);

const internalAutoRotate = ref(props.autoRotate);

const zoom = ref(props.zoomable);

watch(
  () => props.zoomable,
  (zoomable) => {
    zoom.value = zoomable;
  },
);

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

const BACKGROUNDS = ["dark", "space", "stanton", "crusader", "pyro"] as const;

type Background = (typeof BACKGROUNDS)[number];

const BACKGROUND_ICONS: Record<Background, string> = {
  dark: "fa-light fa-moon",
  space: "fa-light fa-stars",
  stanton: "fa-light fa-galaxy",
  crusader: "fa-light fa-planet-moon",
  pyro: "fa-light fa-fire",
};

// Panoramas from the game's own skies, which give ./sky.ts its shapes and colours.
const SKYBOXES: Partial<Record<Background, string>> = {
  stanton: stantonNebula,
  crusader: crusaderNebula,
  pyro: pyroNebula,
};

const background = ref<Background>("dark");

const backgroundName = (name: Background) =>
  t(`labels.holoViewer.background.${name}`);

const skybox = computed(() =>
  props.backgrounds ? SKYBOXES[background.value] : undefined,
);

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

// The camera as the controls left it, so a refit can keep the view.
let liveCamera: PerspectiveCamera | undefined;

type Controls = { object: Camera; target?: Vector3; update?: () => void };

let liveControls: Controls | undefined;

// The orbit controls move the camera without asking for a frame. Each change
// asks for the next one, so a drag, its easing out and an auto-rotation all
// keep drawing, and a camera at rest draws nothing.
const handleControlsChange = (controls: Controls) => {
  liveControls = controls;
  liveCamera = (controls.object as PerspectiveCamera).isPerspectiveCamera
    ? (controls.object as PerspectiveCamera)
    : undefined;

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

// The camera is held to 0.7 of the room's radius. A frame narrow for its
// model fits it from further out than that, and the first drag would pull
// the camera in and cut the model off: the room grows past the fit too.
const ROOM_ZOOM_REACH = 0.7;

const roomScale = computed(() =>
  Math.max(
    modelRoomScale.value,
    (fitDistance.value * 1.15) / (BACKDROP_RADIUS * ROOM_ZOOM_REACH),
  ),
);

watch(roomScale, (scale) => {
  backdrop.value?.scale.setScalar(scale);
  canvas.value?.context?.renderer?.invalidate();
});
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

// Inside the room's walls: past them the room reads as a ball in the dark.
const maxZoomDistance = computed(() =>
  props.backdrop
    ? BACKDROP_RADIUS * roomScale.value * ROOM_ZOOM_REACH
    : Math.max(250, fitDistance.value * 3),
);

const starsVisible = computed(
  () => props.backgrounds && (background.value === "space" || !!skybox.value),
);

const STARS_RADIUS = 1.5;
const STARS_DEPTH = 1;

// The star shell's far side, seen from the camera zoomed all the way out: past
// the model's own far plane on anything larger than a fighter, which clipped
// every star.
const starsReach = computed(
  () => maxZoomDistance.value * (1 + STARS_RADIUS + STARS_DEPTH) * 1.05,
);

const CAMERA_FOV = 35;

// The canvas's, which Tres keeps the camera's own aspect in step with.
const cameraAspect = computed(() => innerWidth.value / innerHeight.value);

const cameraNear = computed(() => nearPlaneFor(fitDistance.value));

const cameraFar = computed(() =>
  Math.max(
    1000,
    fitDistance.value * 4 + modelMaxDimension.value,
    starsVisible.value ? starsReach.value : 0,
  ),
);

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

// Measured once, a contained model keeps the scale of the box it loaded in: a
// modal still opening, or a window resized since, leaves it too large or small.
const lastFrameSize = { width: 0, height: 0 };

// The model last framed, so a contained one can be framed again when its box
// changes size.
const framed = shallowRef<{ size: Vector3; scene: Object3D }>();

const handleModelLoaded = (size: Vector3, scene: Object3D) => {
  // if (props.grid) {
  //   currentModel.value = scene;
  // }

  loading.value = false;
  emit("loaded");

  framed.value = { size, scene };
  lastFrameSize.width = holoViewer.value?.clientWidth ?? 0;
  lastFrameSize.height = holoViewer.value?.clientHeight ?? 0;
  // Framed first: the room is sized past the distance it settles on.
  frameModel(size, scene);
  placeBackdrop(size);
};

// `keepView` scales the camera's distance to the new fit along the way it
// faces now, rather than putting it back in the pose.
const frameModel = (size: Vector3, scene: Object3D, keepView = false) => {
  const bounds = new Box3()
    .setFromObject(scene)
    .getBoundingSphere(new Sphere());
  modelReach.value = Math.max(
    modelReach.value,
    bounds.center.length() + bounds.radius,
  );

  // Get canvas aspect ratio
  const aspect = cameraAspect.value; // width / height

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
  const fovRadians = (CAMERA_FOV * Math.PI) / 180;

  const azimuth = (props.azimuth * Math.PI) / 180;

  if (props.contain) {
    // The frame as it is now: the cached aspect is the one it mounted with.
    const frame = holoViewer.value;
    const frameAspect =
      frame && frame.clientHeight ? frame.clientWidth / frame.clientHeight : 1;
    const elevation = ((props.elevation ?? 0) * Math.PI) / 180;
    const tanVertical = Math.tan(fovRadians / 2);
    const tanHorizontal = tanVertical * frameAspect;

    // The camera's axes, looking at the centred model from the pose. A
    // turntable is framed from every side it can be turned to: fitted from
    // its first angle alone, a ship turned side on runs out of the frame.
    const azimuths = props.turntable
      ? Array.from(
          { length: TURNTABLE_SIDES },
          (_, side) => azimuth + (side * 2 * Math.PI) / TURNTABLE_SIDES,
        )
      : [azimuth];
    const views = azimuths.map((angle) => {
      const toCamera = new Vector3(
        Math.sin(angle) * Math.cos(elevation),
        Math.sin(elevation),
        Math.cos(angle) * Math.cos(elevation),
      );
      const right = new Vector3(0, 1, 0).cross(toCamera).normalize();
      const up = toCamera.clone().cross(right);

      return { toCamera, right, up };
    });

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
        // A skinned mesh's stored points are its bind pose; its bones say
        // where they are drawn.
        if ((mesh as SkinnedMesh).isSkinnedMesh) {
          (mesh as SkinnedMesh).getVertexPosition(index, point);
        } else {
          point.fromBufferAttribute(positions, index);
        }
        point.applyMatrix4(mesh.matrixWorld);

        for (const { toCamera, right, up } of views) {
          const depth = point.dot(toCamera);
          reach = Math.max(
            reach,
            depth + Math.abs(point.dot(right)) / tanHorizontal,
            depth + Math.abs(point.dot(up)) / tanVertical,
          );
        }
      }
    });
    // Room around it: a frame rarely shows its edges whole, the editor's fades
    // in from the left under the controls.
    reach *= props.containPadding;

    const previousReach = fitDistance.value;
    fitDistance.value = reach;
    modelMaxDimension.value = Math.max(size.x, size.y, size.z);

    if (keepView && liveCamera && previousReach > 0) {
      liveCamera.position.multiplyScalar(reach / previousReach);
      liveCamera.near = nearPlaneFor(liveCamera.position.length());
      liveCamera.updateProjectionMatrix();
      const { x, y, z } = liveCamera.position;
      lightPosition.value = [x, y, z];
      canvas.value?.context?.renderer?.invalidate();

      return;
    }

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

const refitContained = useDebounceFn(() => {
  const frame = holoViewer.value;
  if (!props.contain || !framed.value || !frame) return;

  const { clientWidth: width, clientHeight: height } = frame;
  if (width === lastFrameSize.width && height === lastFrameSize.height) return;

  lastFrameSize.width = width;
  lastFrameSize.height = height;
  frameModel(framed.value.size, framed.value.scene, true);
}, 150);

useResizeObserver(holoViewer, () => {
  void refitContained();
});

const handleRenderError = (error: Error) => {
  console.error("HoloViewer render error:", error);
  webglSupported.value = false;
};

const handleModelError = (error: unknown) => {
  loading.value = false;
  emit("unavailable", typeof error === "string" ? error : undefined);

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
      'holo-viewer--framed': backdrop && !internalFullscreen,
      [`holo-viewer--${background}`]: backgrounds,
    }"
  >
    <AppModalCloseBtn
      v-if="internalFullscreen"
      class="holo-viewer__close"
      data-test="holo-viewer-close"
      @click.prevent.stop="disableFullscreen"
    />
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
      <Btn
        v-if="!turntableLocked"
        v-tooltip="zoomTooltip"
        :active="zoom"
        @click="toggleZoom"
      >
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
    <Loader
      v-else-if="busy && webglSupported && !awaitingConfirmation"
      :loading="true"
      data-test="holo-viewer-busy"
    />
    <input v-if="debug" v-model="modelColor" type="color" />
    <WebglFallback v-if="!webglSupported" />
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
      class="holo-viewer__canvas"
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
      <!-- Set as properties, never as `args`: new args build a camera whose uuid
           is copied over, and the orbit controls, keyed by that uuid, come back
           without their change listener, so the light stops following. -->
      <TresPerspectiveCamera
        :position="cameraPosition"
        :fov="CAMERA_FOV"
        :near="cameraNear"
        :far="cameraFar"
      />
      <TresDirectionalLight
        v-if="!ownLighting"
        :position="lightPosition"
        :intensity="textured ? 1.5 : 2"
        :cast-shadow="!lowPower"
      />
      <RoomLighting v-if="textured" />
      <TresAmbientLight
        v-else
        :intensity="ownLighting ? 0.15 : lowPower ? 0.8 : 0.5"
      />
      <OrbitControls
        :auto-rotate="internalAutoRotate"
        :auto-rotate-speed="autoRotateSpeed"
        :enable-rotate="controllable || internalFullscreen"
        :enable-zoom="zoom && !turntableLocked"
        :min-polar-angle="turntableLocked ? turntablePolar : 0"
        :max-polar-angle="
          turntableLocked ? turntablePolar : backdrop ? FLOOR_POLAR : Math.PI
        "
        :zoom-speed="0.5"
        :min-distance="-50"
        :max-distance="maxZoomDistance"
        enable-damping
        :damping-factor="0.25"
        :enable-pan="panable || internalFullscreen"
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
      <primitive v-if="backdrop" :object="backdrop" />
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
          :fullscreen="internalFullscreen"
          :offsetModel="models[models.indexOf(model) - 1]"
          @loaded="handleModelLoaded"
          @error="handleModelError"
          @progress="handleModelProgress"
          @mount-select="emit('mountSelect', $event)"
          @mount-point="emit('mountPoint', $event)"
          @unplaced="emit('unplaced', $event)"
          @fell-back="emit('fellBack', $event)"
          @busy="busy = $event"
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
