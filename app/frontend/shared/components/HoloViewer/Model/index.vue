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
  type Object3D,
  type Texture,
  DoubleSide,
  FrontSide,
  Box3,
  Vector3,
  type Group,
  type AnimationClip,
  Mesh,
  MeshBasicMaterial,
  MeshPhongMaterial,
  MeshLambertMaterial,
  DefaultLoadingManager,
} from "three";
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";
import { sharedDracoLoader } from "../dracoLoader";
import {
  applyHighlights,
  buildMounts,
  mountsHighlightKey,
  mountsLayoutKey,
  releaseMountCache,
  retainMountCache,
} from "../mounts";
import { type HoloModel } from "../index.vue";

type Props = {
  model: HoloModel;
  color?: string;
  onGrid?: boolean;
  mobile?: boolean;
  offsetModel?: HoloModel;
  windowColor?: string;
  // See-through, with the mesh's wireframe drawn over it.
  hologram?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  color: "#428bca",
  onGrid: false,
  mobile: false,
  offsetModel: undefined,
  windowColor: "#1d3d59",
  hologram: false,
});

// One pair for the whole holo, made once: a colour change recolours them
// rather than handing every mesh a fresh pair and leaving the old ones on the
// GPU.
const side = props.mobile ? FrontSide : DoubleSide;
const MaterialClass = props.mobile ? MeshLambertMaterial : MeshPhongMaterial;

// A hologram does not hide what is behind it, so it writes no depth: the far
// side of the hull shows through the near one.
const hologramLook = props.hologram
  ? { transparent: true, opacity: 0.35, depthWrite: false }
  : {};

const material = new MaterialClass({
  color: props.color,
  side,
  ...hologramLook,
});

const HIGHLIGHT_COLOR = "#fbb03b";

// A part the viewer has picked out, in the gold the grid's sections use, and
// drawn over the hull: coolers and drives sit inside it.
const highlightMaterial = new MaterialClass({
  color: HIGHLIGHT_COLOR,
  side,
  ...hologramLook,
  depthTest: false,
});

// The hologram's mesh lines, sharing each body's geometry.
const wireLook = { wireframe: true, transparent: true, depthWrite: false };
const wireMaterial = new MeshBasicMaterial({
  color: props.color,
  opacity: 0.18,
  ...wireLook,
});
const highlightWireMaterial = new MeshBasicMaterial({
  color: HIGHLIGHT_COLOR,
  opacity: 0.4,
  ...wireLook,
  depthTest: false,
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
    if (
      entry === material ||
      entry === windowMaterial ||
      entry === highlightMaterial ||
      entry === wireMaterial ||
      entry === highlightWireMaterial
    ) {
      continue;
    }

    for (const value of Object.values(entry)) {
      if ((value as Texture | null)?.isTexture) (value as Texture).dispose();
    }

    entry.dispose();
  }
};

const highlighted = (node: Object3D) => {
  for (let current: Object3D | null = node; current; current = current.parent) {
    if (current.userData.highlighted) return true;
  }

  return false;
};

// Run again after the highlights change, so it only ever swaps in its own
// materials: a mounted part's originals belong to the holo cache.
const setMaterials = (scene: Group) => {
  const bodies: Mesh[] = [];

  scene.traverse((node) => {
    const mesh = node as Mesh;

    if (!mesh.isMesh || mesh.userData.wire) return;

    if (!mesh.userData.shared) disposeOriginal(mesh.material);

    if (windowRefs.some((item) => node.name.toLowerCase().includes(item))) {
      mesh.material = windowMaterial;
    } else {
      mesh.material = highlighted(node) ? highlightMaterial : material;
      // Last, so nothing drawn after it covers it again.
      mesh.renderOrder = highlighted(node) ? 1 : 0;
      bodies.push(mesh);
    }
  });

  if (!props.hologram) return;

  // Added once the walk is done, so it never visits its own lines.
  for (const body of bodies) {
    const wireMaterialFor = highlighted(body)
      ? highlightWireMaterial
      : wireMaterial;
    const existing = body.children.find(
      (child) => child.userData.wire,
    ) as Mesh | undefined;

    if (existing) {
      existing.material = wireMaterialFor;
      existing.renderOrder = body.renderOrder;
      continue;
    }

    const wire = new Mesh(body.geometry, wireMaterialFor);
    wire.userData.wire = true;
    wire.renderOrder = body.renderOrder;
    body.add(wire);
  }
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

  // Into the first frame's pose before the scene is measured and centred: the
  // bind pose may have the gear or wings somewhere the animation never shows.
  mixer.value.update(0);
};

retainMountCache();

onUnmounted(() => {
  releaseMountCache();
  mixer.value?.stopAllAction();
  material.dispose();
  windowMaterial.dispose();
  highlightMaterial.dispose();
  wireMaterial.dispose();
  highlightWireMaterial.dispose();
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

// The parts on the holo's ports, in the export's frame: added after the hull is
// centred, so the camera frames the ship alike whatever it carries, and
// replaced in place when the fitting changes.
let mountRoot: Group | undefined;

// Two quick swaps load in parallel; only the latest may land.
let mountsRequest = 0;

const attachMounts = async (scene: Group) => {
  const request = ++mountsRequest;
  const mounts = props.model.mounts;
  const next = mounts?.length ? await buildMounts(mounts) : undefined;

  if (request !== mountsRequest) return;

  if (mountRoot) scene.remove(mountRoot);
  mountRoot = next;

  if (next) {
    // Built from the mounts as they were asked for; a highlight may have moved
    // while the parts loaded.
    applyHighlights(next, props.model.mounts ?? []);
    scene.add(next);
    setMaterials(next);
  }
};

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

  void attachMounts(scene);
};

watch(
  () => state.value,
  () => {
    if (state.value) {
      setup(state.value.scene, state.value.animations);
    }
  },
);

// By content: a fitting recomputed into an equal tree is not a swap.
watch(
  () => mountsLayoutKey(props.model.mounts),
  () => {
    if (state.value) void attachMounts(state.value.scene);
  },
);

// A highlight only repaints the parts already there.
watch(
  () => mountsHighlightKey(props.model.mounts),
  () => {
    if (!mountRoot) return;

    applyHighlights(mountRoot, props.model.mounts ?? []);
    setMaterials(mountRoot);
  },
);

watch(
  () => props.color,
  (color) => {
    material.color.set(color);
    wireMaterial.color.set(color);
  },
);
</script>

<template>
  <primitive v-if="state" :object="state.scene" />
</template>
