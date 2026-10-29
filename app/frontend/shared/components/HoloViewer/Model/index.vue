<!-- eslint-disable import/no-self-import -->
<script lang="ts">
export default {
  name: "HoloViewerModel",
};
</script>

<script setup lang="ts">
import { useLoader, useLoop, useTres } from "@tresjs/core";
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
  type BufferGeometry,
  EdgesGeometry,
  LineBasicMaterial,
  LineSegments,
  MeshPhongMaterial,
  MeshLambertMaterial,
  type MeshStandardMaterial,
  DefaultLoadingManager,
  type ColorSpace,
  NoColorSpace,
  SRGBColorSpace,
  TextureLoader,
} from "three";
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";
import { prepareGltfLoader } from "../gltfLoader";
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
// A hologram has no shine: a highlight that follows the eye would brighten a
// part from one angle and not another.
const MaterialClass =
  props.mobile || props.hologram ? MeshLambertMaterial : MeshPhongMaterial;

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

// Mounted parts a brighter, fuller blue than the hull in a hologram: inside
// the see-through hull, in its own colour, a cooler or a drive is lost in it.
const PART_SATURATION = props.hologram ? 0.2 : 0;
const PART_LIGHTNESS = props.hologram ? 0.1 : 0;
const PART_OPACITY = 0.5;
const partColor = new Color();

const updatePartColor = () =>
  partColor
    .copy(material.color)
    .offsetHSL(0, PART_SATURATION, PART_LIGHTNESS);

// The hologram's layers in a fixed order. Sorted by distance instead, a part
// sat over the hull from one side and under it from the other, and a body and
// its own lines -- at the same distance but for a rounding -- swapped from one
// part to the next: lines over the body read as a bright part, lines under it
// as a dim one. Lines go over their body everywhere.
const RENDER_ORDER = props.hologram
  ? { hullWire: 1, part: 2, partWire: 3, overlay: 4 }
  : { hullWire: 0, part: 0, partWire: 0, overlay: 1 };

updatePartColor();

// The hologram's mesh lines: only the edges where the surface turns, not every
// triangle -- a hull's few hundred thousand made every frame crawl -- worked
// out once per geometry and shared by every copy of a part.
const EDGE_ANGLE = 20;
const edgesOf = new WeakMap<BufferGeometry, EdgesGeometry>();

// Finding the edges walks every triangle on the main thread: an Ironclad's
// hull, at nine million points, held the page for good. A mesh that large
// keeps its see-through body without the lines.
const EDGE_POINT_LIMIT = 500_000;

const edgesFor = (geometry: BufferGeometry) => {
  let edges = edgesOf.get(geometry);

  if (!edges) {
    edges = new EdgesGeometry(geometry, EDGE_ANGLE);
    edgesOf.set(geometry, edges);
  }

  return edges;
};

const WIRE_OPACITY = 0.35;
// Fainter on a part: drawn over its body, its dense lines at the hull's
// strength washed it out to near white.
const PART_WIRE_OPACITY = 0.15;
const HIGHLIGHT_WIRE_OPACITY = 0.7;

const wireLook = { transparent: true, depthWrite: false };
const wireMaterial = new LineBasicMaterial({
  color: props.color,
  opacity: WIRE_OPACITY,
  ...wireLook,
});
const windowMaterial = new MaterialClass({
  color: props.windowColor,
  opacity: 0.8,
  transparent: true,
  side,
  ...(props.hologram ? { depthWrite: false } : {}),
});

// Sorted by distance, a window would land over the hull at some angles and
// under it at others, and the far side's glass would come and go as the holo
// turns. Drawn first, the hull always washes over it.
const WINDOW_RENDER_ORDER = props.hologram ? -1 : 0;

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
  body: Material & { color: Color };
  wire?: LineBasicMaterial;
  // The glow seen through the hull: coolers and drives sit inside it. Its own
  // layer, faded with the glow, so the part never jumps behind the hull.
  overlay: Mesh<Mesh["geometry"], MeshBasicMaterial>;
  glow: number;
  target: number;
};

const fading = new Map<Mesh, Fading>();

// A quarter of a second from one to the other.
const FADE_PER_SECOND = 4;

const OVERLAY_OPACITY = 0.45;

const applyGlow = (entry: Fading) => {
  // Eased at both ends rather than run at a constant rate.
  const glow = entry.glow * entry.glow * (3 - 2 * entry.glow);

  entry.body.color.copy(partColor).lerp(HIGHLIGHT_COLOR, glow);

  entry.overlay.material.opacity = OVERLAY_OPACITY * glow;
  entry.overlay.visible = glow > 0;

  if (entry.wire) {
    entry.wire.color.copy(partColor).lerp(HIGHLIGHT_COLOR, glow);
    entry.wire.opacity =
      PART_WIRE_OPACITY + (HIGHLIGHT_WIRE_OPACITY - PART_WIRE_OPACITY) * glow;
  }
};

const partMaterial = () => {
  const own = material.clone() as Fading["body"];
  if (props.hologram) own.opacity = PART_OPACITY;

  return own;
};

const disposeFading = (root: Object3D) => {
  root.traverse((node) => {
    const entry = fading.get(node as Mesh);
    if (!entry) return;

    entry.body.dispose();
    entry.wire?.dispose();
    entry.overlay.material.dispose();
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
  body.children.find((child) => child.userData.wire) as
    LineSegments<EdgesGeometry, LineBasicMaterial> | undefined;

const overlayFor = (body: Mesh) => {
  const overlay = new Mesh(
    body.geometry,
    new MeshBasicMaterial({
      color: HIGHLIGHT_COLOR,
      transparent: true,
      opacity: 0,
      depthTest: false,
      depthWrite: false,
      side,
    }),
  );
  // Marked so a later walk leaves it alone.
  overlay.userData.overlay = true;
  overlay.renderOrder = RENDER_ORDER.overlay;
  overlay.visible = false;
  body.add(overlay);

  return overlay;
};

// Run again after the highlights change, so it only ever swaps in its own
// materials: a mounted part's originals belong to the holo cache.
const setMaterials = (scene: Group) => {
  const bodies: Mesh[] = [];

  scene.traverse((node) => {
    const mesh = node as Mesh;

    if (!mesh.isMesh || mesh.userData.wire || mesh.userData.overlay) return;

    if (!mesh.userData.shared) disposeOriginal(mesh.material);

    if (windowRefs.some((item) => node.name.toLowerCase().includes(item))) {
      mesh.material = windowMaterial;
      mesh.renderOrder = WINDOW_RENDER_ORDER;
    } else {
      bodies.push(mesh);
    }
  });

  for (const body of bodies) {
    const own = withinMounts(body);

    const lined =
      props.hologram &&
      (body.geometry.getAttribute("position")?.count ?? 0) <= EDGE_POINT_LIMIT;

    if (lined && !wireOf(body)) {
      const wire = new LineSegments(edgesFor(body.geometry), wireMaterial);
      wire.userData.wire = true;
      wire.renderOrder = RENDER_ORDER.hullWire;
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
        body: partMaterial(),
        wire: props.hologram ? wireMaterial.clone() : undefined,
        overlay: overlayFor(body),
        glow: target,
        target,
      };
      fading.set(body, entry);
      applyGlow(entry);
    }

    entry.target = target;
    body.material = entry.body;

    body.renderOrder = RENDER_ORDER.part;

    const wire = wireOf(body);
    if (wire && entry.wire) wire.material = entry.wire;
    if (wire) wire.renderOrder = RENDER_ORDER.partWire;
  }

  invalidate();
};

const mixer = shallowRef<AnimationMixer>();

const { onBeforeRender } = useLoop();

// A viewer drawing on demand draws a frame only when asked: for every change
// made here, and each step of a fade until it is done.
const { invalidate } = useTres();

onBeforeRender(({ delta }) => {
  mixer.value?.update(delta);

  let moving = false;

  for (const entry of fading.values()) {
    if (entry.glow === entry.target) continue;

    // Capped: drawing on demand, the first frame after a pause reports the
    // whole pause as its delta, and the fade would end in one step.
    const step = Math.min(delta, 1 / 30) * FADE_PER_SECOND;
    entry.glow =
      entry.target > entry.glow
        ? Math.min(entry.target, entry.glow + step)
        : Math.max(entry.target, entry.glow - step);
    applyGlow(entry);
    moving = true;
  }

  if (moving) invalidate();
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
  // A paint still loading would land after this and never be freed.
  paintRequest += 1;
  paintMaps.forEach((map) => map.dispose());
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
      prepareGltfLoader(loader);
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

  invalidate();
};

// The body is the one mesh a paint recolours; decals and glass keep theirs.
const bodyMaterials = (scene: Group) => {
  const materials = new Set<MeshStandardMaterial>();

  scene.traverse((node) => {
    if (!node.name.endsWith("_body")) return;

    node.traverse((child) => {
      const mesh = child as Mesh;
      if (mesh.isMesh) materials.add(mesh.material as MeshStandardMaterial);
    });
  });

  return [...materials];
};

// The export's own paint, kept to switch back to.
type OwnPaint = {
  map: Texture | null;
  orm: Texture | null;
  roughness: number;
  metalness: number;
};

let paintMaps: Texture[] = [];
let paintRequest = 0;

const loadPaintMap = (url?: string) =>
  url
    ? new TextureLoader().loadAsync(url).catch(() => undefined)
    : Promise.resolve(undefined);

// Written like the export's own maps, which are in glTF's orientation.
const preparePaintMap = (
  map: Texture,
  like: Texture | null,
  colorSpace: ColorSpace,
) => {
  map.colorSpace = colorSpace;
  map.flipY = false;
  if (!like) return;

  map.wrapS = like.wrapS;
  map.wrapT = like.wrapT;
  map.anisotropy = like.anisotropy;
};

const applyPaint = async (scene: Group) => {
  const request = ++paintRequest;
  const [map, loadedOrm] = await Promise.all([
    loadPaintMap(props.model.paint),
    loadPaintMap(props.model.paint && props.model.paintOrm),
  ]);

  // Only with its own base colour: a metal paint's ORM under another paint's
  // colours would turn the wrong parts to metal.
  const orm = map ? loadedOrm : undefined;
  if (!orm) loadedOrm?.dispose();

  if (request !== paintRequest) {
    map?.dispose();
    orm?.dispose();
    return;
  }

  bodyMaterials(scene).forEach((bodyMaterial) => {
    const own = (bodyMaterial.userData.ownPaint ??= {
      map: bodyMaterial.map,
      orm: bodyMaterial.roughnessMap,
      roughness: bodyMaterial.roughness,
      metalness: bodyMaterial.metalness,
    }) as OwnPaint;

    if (map) preparePaintMap(map, own.map, SRGBColorSpace);
    if (orm) preparePaintMap(orm, own.map, NoColorSpace);

    bodyMaterial.map = map ?? own.map;
    bodyMaterial.roughnessMap = orm ?? own.orm;
    bodyMaterial.metalnessMap = orm ?? own.orm;
    // Factors of 1, so the maps alone decide.
    bodyMaterial.roughness = orm ? 1 : own.roughness;
    bodyMaterial.metalness = orm ? 1 : own.metalness;
    bodyMaterial.needsUpdate = true;
  });

  paintMaps.forEach((paintMap) => paintMap.dispose());
  paintMaps = [map, orm].filter((paintMap) => paintMap !== undefined);

  invalidate();
};

const setup = (scene: Group, animations: AnimationClip[]) => {
  if (props.model.textured) {
    playAnimations(scene, animations);
    if (props.model.paint) void applyPaint(scene);
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
  () => [props.model.paint, props.model.paintOrm],
  () => {
    if (state.value && props.model.textured) void applyPaint(state.value.scene);
  },
);

watch(
  () => props.color,
  (color) => {
    material.color.set(color);
    wireMaterial.color.set(color);
    updatePartColor();
    fading.forEach(applyGlow);
  },
);
</script>

<template>
  <primitive v-if="state" :object="state.scene" />
</template>
