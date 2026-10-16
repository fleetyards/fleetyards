<!-- eslint-disable import/no-self-import -->
<script lang="ts">
export default {
  name: "HoloViewerModel",
};
</script>

<script setup lang="ts">
import { useLoader, useLoop } from "@tresjs/core";
import {
  AnimationMixer,
  type Material,
  type Mesh,
  type Texture,
  DoubleSide,
  FrontSide,
  Box3,
  Vector3,
  type Group,
  type AnimationClip,
  MeshPhongMaterial,
  MeshLambertMaterial,
  DefaultLoadingManager,
} from "three";
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";
import { sharedDracoLoader } from "../dracoLoader";
import { type HoloModel } from "../index.vue";

type Props = {
  model: HoloModel;
  color?: string;
  onGrid?: boolean;
  mobile?: boolean;
  offsetModel?: HoloModel;
  windowColor?: string;
};

const props = withDefaults(defineProps<Props>(), {
  color: "#428bca",
  onGrid: false,
  mobile: false,
  offsetModel: undefined,
  windowColor: "#1d3d59",
});

// One pair for the whole holo, made once: a colour change recolours them
// rather than handing every mesh a fresh pair and leaving the old ones on the
// GPU.
const side = props.mobile ? FrontSide : DoubleSide;
const MaterialClass = props.mobile ? MeshLambertMaterial : MeshPhongMaterial;

const material = new MaterialClass({
  color: props.color,
  side,
});

const windowMaterial = new MaterialClass({
  color: props.windowColor,
  opacity: 0.8,
  transparent: true,
  side,
});

const windowRefs = ["window", "glass"];

// The export's own materials and their textures are replaced on load, and
// nothing else holds them.
const disposeOriginal = (original: Material | Material[]) => {
  for (const entry of Array.isArray(original) ? original : [original]) {
    if (entry === material || entry === windowMaterial) continue;

    for (const value of Object.values(entry)) {
      if ((value as Texture | null)?.isTexture) (value as Texture).dispose();
    }

    entry.dispose();
  }
};

const setMaterials = (scene: Group) => {
  scene.traverse((node) => {
    const mesh = node as Mesh;

    if (!mesh.isMesh) return;

    disposeOriginal(mesh.material);

    mesh.material = windowRefs.some((item) =>
      node.name.toLowerCase().includes(item),
    )
      ? windowMaterial
      : material;
  });
};

const mixer = shallowRef<AnimationMixer>();

const { onBeforeRender } = useLoop();

onBeforeRender(({ delta }) => {
  mixer.value?.update(delta);
});

const playAnimations = (scene: Group, animations: AnimationClip[]) => {
  mixer.value?.stopAllAction();
  mixer.value = undefined;

  if (!animations.length) return;

  mixer.value = new AnimationMixer(scene);

  animations.forEach((clip) => {
    mixer.value?.clipAction(clip).play();
  });
};

onUnmounted(() => {
  mixer.value?.stopAllAction();
  material.dispose();
  windowMaterial.dispose();
});

const emit = defineEmits(["loaded", "error", "progress"]);

DefaultLoadingManager.onProgress = (_item, loaded, total) => {
  emit("progress", loaded, total);
};

DefaultLoadingManager.onError = (error) => {
  emit("error", error);
  console.error("Error loading GLTF model", error);
};

const { state } = useLoader(GLTFLoader, props.model.path, {
  extensions: (loader) => {
    if (loader instanceof GLTFLoader) {
      loader.setDRACOLoader(sharedDracoLoader());
    }
  },
});

const setup = (scene: Group, animations: AnimationClip[]) => {
  if (props.model.textured) {
    playAnimations(scene, animations);
  } else {
    setMaterials(scene);
  }

  const box = new Box3().setFromObject(scene);
  const size = box.getSize(new Vector3());

  if (props.onGrid && props.model.length) {
    const scale = props.model.length / size.x;
    scene.scale.setScalar(scale);
    size.multiplyScalar(scale);
  }

  scene.updateMatrixWorld(true);
  const scaledBox = new Box3().setFromObject(scene);
  const center = scaledBox.getCenter(new Vector3());
  scene.position.sub(center);

  if (props.offsetModel?.length) {
    scene.position.y += props.offsetModel.length;
  }

  emit("loaded", size, scene);
};

watch(
  () => state.value,
  () => {
    if (state.value) {
      setup(state.value.scene, state.value.animations);
    }
  },
);

watch(
  () => props.color,
  (color) => {
    material.color.set(color);
  },
);
</script>

<template>
  <primitive v-if="state" :object="state.scene" />
</template>
