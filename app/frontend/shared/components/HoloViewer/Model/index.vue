<!-- eslint-disable import/no-self-import -->
<script lang="ts">
export default {
  name: "HoloViewerModel",
};
</script>

<script setup lang="ts">
import { useGLTF } from "@tresjs/cientos";
import {
  type Mesh,
  DoubleSide,
  FrontSide,
  Box3,
  Vector3,
  type Group,
  MeshPhongMaterial,
  MeshLambertMaterial,
  DefaultLoadingManager,
} from "three";
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

const setMaterials = (scene: Group) => {
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

  scene.traverse((node) => {
    if (!(node as Mesh).isMesh) return;

    if (windowRefs.some((item) => node.name.toLowerCase().includes(item))) {
      (node as Mesh).material = windowMaterial;
    } else {
      (node as Mesh).material = material;
    }
  });
};

const emit = defineEmits(["loaded", "error", "progress"]);

DefaultLoadingManager.onProgress = (_item, loaded, total) => {
  emit("progress", loaded, total);
};

DefaultLoadingManager.onError = (error) => {
  emit("error", error);
  console.error("Error loading GLTF model", error);
};

const { state } = useGLTF(props.model.path, { draco: true });

const setup = (scene: Group) => {
  setMaterials(scene);

  const box = new Box3().setFromObject(scene);
  const size = box.getSize(new Vector3());

  if (props.onGrid && props.model.length) {
    scene.scale.setScalar(props.model.length / size.x);
  }

  if (props.offsetModel?.length) {
    const offset = props.offsetModel.length;
    scene.position.setY(offset);
  }

  emit("loaded", size, scene);
};

watch(
  () => state.value,
  () => {
    if (state.value) {
      setup(state.value.scene);
    }
  },
);

watch(
  () => props.color,
  () => {
    if (state.value) {
      setMaterials(state.value.scene);
    }
  },
);
</script>

<template>
  <primitive v-if="state" :object="state.scene" />
</template>
