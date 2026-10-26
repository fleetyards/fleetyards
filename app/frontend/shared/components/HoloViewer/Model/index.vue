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
  Color,
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

// A part the viewer has picked out, in the gold the grid's sections use.
const HIGHLIGHT_COLOR = new Color("#fbb03b");

// The hologram's mesh lines, sharing each body's geometry.
const wireLook = { wireframe: true, transparent: true, depthWrite: false };
const wireMaterial = new MeshBasicMaterial({
  color: props.color,
  opacity: 0.18,
  ...wireLook,
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
      entry === wireMaterial
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

// A mounted part's own pair of materials, eased between the holo's colour and
// the highlight: `glow` runs from 0 to 1 and follows `target`.
type Fading = {
  mesh: Mesh;
  body: Material & { color: Color; depthTest: boolean };
  wire?: MeshBasicMaterial;
  glow: number;
  target: number;
};

const fading = new Map<Mesh, Fading>();

// A quarter of a second from one to the other.
const FADE_PER_SECOND = 4;

const WIRE_OPACITY = 0.18;
const HIGHLIGHT_WIRE_OPACITY = 0.4;

const applyGlow = (entry: Fading) => {
  const { glow } = entry;
  // Drawn over the hull while it shows at all: coolers and drives sit inside.
  const overHull = glow > 0;

  entry.body.color.copy(material.color).lerp(HIGHLIGHT_COLOR, glow);
  entry.body.depthTest = !overHull;
  entry.mesh.renderOrder = overHull ? 1 : 0;

  if (entry.wire) {
    entry.wire.color.copy(wireMaterial.color).lerp(HIGHLIGHT_COLOR, glow);
    entry.wire.opacity =
      WIRE_OPACITY + (HIGHLIGHT_WIRE_OPACITY - WIRE_OPACITY) * glow;
    entry.wire.depthTest = !overHull;
  }
};

const disposeFading = (root: Object3D) => {
  root.traverse((node) => {
    const entry = fading.get(node as Mesh);
    if (!entry) return;

    entry.body.dispose();
    entry.wire?.dispose();
    fading.delete(entry.mesh);
  });
};

const withinMounts = (node: Object3D) => {
  for (let current: Object3D | null = node; current; current = current.parent) {
    if (current === mountRoot) return true;
  }

  return false;
};

const wireOf = (body: Mesh) =>
  body.children.find((child) => child.userData.wire) as Mesh | undefined;

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
      bodies.push(mesh);
    }
  });

  for (const body of bodies) {
    const own = withinMounts(body);

    if (props.hologram && !wireOf(body)) {
      const wire = new Mesh(body.geometry, wireMaterial);
      wire.userData.wire = true;
      body.add(wire);
    }

    if (!own) {
      body.material = material;
      continue;
    }

    let entry = fading.get(body);
    const target = highlighted(body) ? 1 : 0;

    if (!entry) {
      // A part built with its highlight already on shows it at once.
      entry = {
        mesh: body,
        body: material.clone() as Fading["body"],
        wire: props.hologram ? wireMaterial.clone() : undefined,
        glow: target,
        target,
      };
      fading.set(body, entry);
      applyGlow(entry);
    }

    entry.target = target;
    body.material = entry.body;

    const wire = wireOf(body);
    if (wire && entry.wire) wire.material = entry.wire;
  }
};

const mixer = shallowRef<AnimationMixer>();

const { onBeforeRender } = useLoop();

onBeforeRender(({ delta }) => {
  mixer.value?.update(delta);

  for (const entry of fading.values()) {
    if (entry.glow === entry.target) continue;

    const step = delta * FADE_PER_SECOND;
    entry.glow =
      entry.target > entry.glow
        ? Math.min(entry.target, entry.glow + step)
        : Math.max(entry.target, entry.glow - step);
    applyGlow(entry);
  }
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
  wireMaterial.dispose();
  if (mountRoot) disposeFading(mountRoot);
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

  if (mountRoot) {
    scene.remove(mountRoot);
    disposeFading(mountRoot);
  }
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
    fading.forEach(applyGlow);
  },
);
</script>

<template>
  <primitive v-if="state" :object="state.scene" />
</template>
