<script setup lang="ts">
import { useGLTF } from "@tresjs/cientos";
import {
  type Mesh,
  type Scene,
  DoubleSide,
  Box3,
  Vector3,
  MeshPhongMaterial,
} from "three";

type Props = {
  path: string;
  color?: string;
  windowColor?: string;
};

const props = withDefaults(defineProps<Props>(), {
  color: "#428bca",
  windowColor: "#1d3d59",
});

const setMaterials = (scene: Scene) => {
  const material = new MeshPhongMaterial({
    color: props.color,
    side: DoubleSide,
  });

  const windowMaterial = new MeshPhongMaterial({
    color: props.windowColor,
    opacity: 0.8,
    transparent: true,
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

const scene = await useGLTF(props.path, { draco: true }, (loader) => {
  loader.manager.onProgress = (_item, loaded, total) => {
    emit("progress", loaded, total);
  };
})
  .then(({ scene }) => {
    setMaterials(scene);

    scene.rotation.set(0, 45, 0);

    const box = new Box3().setFromObject(scene);
    const size = box.getSize(new Vector3());

    emit("loaded", size);

    return scene;
  })
  .catch((error) => {
    emit("error", error);
    console.error("Error loading GLTF model", error);
  });

watch(
  () => props.color,
  () => {
    if (scene) {
      setMaterials(scene);
    }
  },
);
</script>

<template>
  <primitive v-if="scene" :object="scene" />
</template>
