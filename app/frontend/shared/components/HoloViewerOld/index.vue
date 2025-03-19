<script lang="ts">
export default {
  name: "HoloViewer",
};
</script>

<script lang="ts" setup>
import Loader from "@/shared/components/Loader/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import * as THREE from "three";
import type { Mesh } from "three";
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";
import { DRACOLoader } from "three/examples/jsm/loaders/DRACOLoader.js";
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls.js";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useI18n } from "@/shared/composables/useI18n";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";

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

const { t } = useI18n();

const { displayAlert } = useAppNotifications();

const modelColor = ref(0x428bca);

const windowColor = 0x1d3d59;

const autoRotateSpeed = 1.5;

const loading = ref(false);

const debug = ref(false);

let scene: THREE.Scene | undefined = undefined;

let camera: THREE.Camera | undefined = undefined;

let renderer: THREE.Renderer | undefined = undefined;

let model: THREE.Group | undefined = undefined;

let controls: OrbitControls | undefined = undefined;

const autoRotate = ref(true);

const zoom = ref(false);

const progress = ref(0);

const color = ref(false);

const modelViewer = ref<HTMLElement | undefined>();

const internalFullscreen = ref(props.fullscreen);

const enableFullscreen = async () => {
  if (internalFullscreen.value) {
    return;
  }

  internalFullscreen.value = true;

  await nextTick();

  if (renderer && elementWidth.value && elementHeight.value) {
    console.log("foo", elementWidth.value, elementHeight.value);
    renderer.setSize(elementWidth.value, elementHeight.value);
  }

  setupControls();
};

const disableFullscreen = async () => {
  if (!internalFullscreen.value) {
    return;
  }

  internalFullscreen.value = false;

  await nextTick();

  if (renderer && elementWidth.value && elementHeight.value) {
    renderer.setSize(elementWidth.value, elementHeight.value);
  }

  setupControls();
};

const elementWidth = computed(() => {
  return modelViewer.value?.clientWidth;
});

const elementHeight = computed(() => {
  return modelViewer.value?.clientHeight;
});

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

watch(
  () => modelColor.value,
  () => {
    updateModelMaterial();
  },
);

watch(
  () => zoom.value,
  () => {
    if (controls) {
      controls.enableZoom = zoom.value;
      controls.update();
    }
  },
);

watch(
  () => color.value,
  () => {
    if (model) {
      updateModelMaterial();
    }
  },
);

watch(
  () => autoRotate.value,
  () => {
    if (controls) {
      controls.autoRotate = autoRotate.value;
      controls.update();
    }
  },
);

onMounted(() => {
  setup();
});

const setup = () => {
  loading.value = true;
  progress.value = 0;

  scene = setupScene();
  camera = setupCamera();
  if (camera) {
    scene.add(camera);
  }
  renderer = setupRenderer();
  controls = setupControls(renderer.domElement, camera);

  loadModel();
};

const animate = () => {
  if (!scene || !camera) {
    return;
  }

  controls?.update();

  requestAnimationFrame(animate);

  renderer?.render(scene, camera);
};

const setupScene = () => {
  const scene = new THREE.Scene();

  scene.background = null;

  return scene;
};

const setupCamera = () => {
  if (!elementWidth.value || !elementHeight.value) {
    return;
  }

  const camera = new THREE.PerspectiveCamera(
    35,
    elementWidth.value / elementHeight.value,
    0.1,
    1000,
  );

  return camera;
};

const setupControls = (domElement: HTMLElement, camera?: THREE.Camera) => {
  if (!camera) {
    return;
  }

  const controls = new OrbitControls(camera, domElement);

  controls.enableDamping = true;
  controls.dampingFactor = 0.25;

  controls.enablePan = false;

  controls.enableZoom = zoom.value;
  controls.minDistance = 50;
  controls.maxDistance = 250;

  controls.enableRotate = props.controllable || internalFullscreen.value;

  controls.autoRotate = autoRotate.value;
  controls.autoRotateSpeed = autoRotateSpeed;

  controls.listenToKeyEvents(window);

  controls.update();

  return controls;
};

const rendererElement = ref<HTMLElement | undefined>();

const setupRenderer = () => {
  const renderer = new THREE.WebGLRenderer({
    antialias: true,
    alpha: true,
  });

  if (rendererElement.value) {
    modelViewer.value?.removeChild(rendererElement.value);
  }

  renderer.outputColorSpace = THREE.SRGBColorSpace;
  renderer.setPixelRatio(window.devicePixelRatio);
  renderer.toneMappingExposure = 1;
  if (elementWidth.value && elementHeight.value) {
    renderer.setSize(elementWidth.value, elementHeight.value);
  }
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;

  rendererElement.value = renderer.domElement;
  modelViewer.value?.appendChild(rendererElement.value);

  return renderer;
};

const setupDirectionalLight = (objectModel: THREE.Object3D<THREE.Event>) => {
  const directionalLight = new THREE.DirectionalLight(0x404040, 60);

  directionalLight.target = objectModel;
  directionalLight.castShadow = true;

  return directionalLight;
};

const updateModelMaterial = () => {
  const material = new THREE.MeshPhongMaterial({
    color: modelColor.value,
    side: THREE.DoubleSide,
  });

  const windowMaterial = new THREE.MeshPhongMaterial({
    color: windowColor,
    opacity: 0.8,
    transparent: true,
  });

  const windowRefs = ["window", "glass"];

  model?.traverse((node) => {
    if (!(node as Mesh).isMesh) return;

    if (windowRefs.some((item) => node.name.toLowerCase().includes(item))) {
      (node as Mesh).material = windowMaterial;
    } else {
      (node as Mesh).material = material;
    }
  });
};

const loadModel = () => {
  const loader = new GLTFLoader();

  const dracoLoader = new DRACOLoader();
  dracoLoader.setDecoderPath("/vendor/js/draco/");
  loader.setDRACOLoader(dracoLoader);

  try {
    loader.load(
      props.holo,
      (gltf) => {
        loading.value = false;

        model = gltf.scene;

        model.rotation.set(0, 45, 0);

        updateModelMaterial();

        scene?.add(model);

        const box = new THREE.Box3().setFromObject(model);
        const size = box.getSize(new THREE.Vector3());

        const maxValue = Math.max(size.x, size.y);

        const cameraAngle = props.inline ? 15 : 30;

        const zValue =
          props.inline && !internalFullscreen.value
            ? Math.max(maxValue * 1.1, size.y * 1.1)
            : Math.max(maxValue * 1.5, size.y * 2);

        camera?.position.set(0, cameraAngle, zValue);

        camera?.add(setupDirectionalLight(model));

        animate();
      },
      (xhr) => {
        progress.value = (xhr.loaded / xhr.total) * 100;
      },
      (error) => {
        handleError(error);
      },
    );
  } catch (error) {
    handleError(error);
  }
};

const handleError = (error: unknown) => {
  loading.value = false;

  console.error(error);

  displayAlert({
    text: t("messages.holoViewer.modelLoader.failure"),
  });
};

const toggleZoom = () => {
  zoom.value = !zoom.value;
};

const toggleColor = () => {
  color.value = !color.value;
};

const toggleAutoRotate = () => {
  autoRotate.value = !autoRotate.value;
};

defineExpose({
  fullscreen: internalFullscreen,
  enableFullscreen,
  disableFullscreen,
});
</script>

<template>
  <div
    ref="modelViewer"
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
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
