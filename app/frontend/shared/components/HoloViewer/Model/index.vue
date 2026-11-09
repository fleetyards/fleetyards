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
  type SkinnedMesh,
  DoubleSide,
  FrontSide,
  Box3,
  Matrix4,
  Quaternion,
  Vector3,
  Group,
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
  DefaultLoadingManager,
  NoColorSpace,
  SRGBColorSpace,
  TextureLoader,
  Raycaster,
  Vector2,
} from "three";
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";
import { extrasLoadingManager, prepareGltfLoader } from "../gltfLoader";
import { gridScale } from "../gridScale";
import {
  applyStencilMap,
  BODY_SUFFIX,
  partMaterials,
  preparePaintMap,
} from "../paintMaps";
import {
  disposeCharacter,
  dressHead,
  dressNeck,
  fitPieceToFace,
  loadCharacter,
  type LoadedCharacter,
} from "../character/applyCharacter";
import { buildPedestal, disposePedestal } from "../pedestal";
import {
  bindToBones,
  bodyRegion,
  bonesByName,
  buildRigLights,
  rigLightsKey,
  type RigAttachment,
  type RigPiece,
  cloneRigPiece,
  loadClips,
  rigLayoutKey,
} from "../rig";
import {
  applyHighlights,
  buildMounts,
  cloneShared,
  disposeTextures,
  loadHolo,
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
  // Mounted parts answer the pointer, named by their mount's id.
  pickable?: boolean;
  // Shown full screen: a figure stands without its pedestal there.
  fullscreen?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  color: "#428bca",
  onGrid: false,
  mobile: false,
  offsetModel: undefined,
  windowColor: "#1d3d59",
  hologram: false,
  pickable: false,
  fullscreen: false,
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
  partColor.copy(material.color).offsetHSL(0, PART_SATURATION, PART_LIGHTNESS);

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

    disposeTextures(entry);
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

// A painted part keeps the materials it was exported with.
const withinTexturedMount = (node: Object3D) => {
  for (let current: Object3D | null = node; current; current = current.parent) {
    if (current.userData.textured) return true;
    if (current === mountRoot) return false;
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
    if (withinTexturedMount(mesh)) return;

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

// Parts, a character or a paint loading after the model itself: the viewer
// shows it is still at work until the last of them lands.
let inFlight = 0;

const whileBusy = async <T,>(work: Promise<T>) => {
  if (inFlight++ === 0) emit("busy", true);
  try {
    return await work;
  } finally {
    if (--inFlight === 0) emit("busy", false);
  }
};

const { onBeforeRender } = useLoop();

// A viewer drawing on demand draws a frame only when asked: for every change
// made here, and each step of a fade until it is done.
const { invalidate, camera, renderer } = useTres();

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

// Ends the retries in `setup`: a viewer gone mid-load stops asking.
let unmounted = false;

onUnmounted(() => {
  unmounted = true;
  releaseMountCache();
  mixer.value?.stopAllAction();
  material.dispose();
  windowMaterial.dispose();
  wireMaterial.dispose();
  // A paint still loading would land after this and never be freed.
  paintRequest += 1;
  paintMaps.forEach((map) => map.dispose());
  if (mountRoot) disposeFading(mountRoot);
  if (pedestal) disposePedestal(pedestal);
  // The body model is cached for the next viewer: it gets its own head back.
  undressNeck?.();
  undressHead?.();
  if (character) disposeCharacter(character);
  if (readyCharacter) disposeCharacter(readyCharacter);
  fittedGeometries.forEach((geometry) => geometry.dispose());
});

const emit = defineEmits<{
  loaded: [size: Vector3, scene: Group];
  error: [error: unknown];
  progress: [loaded: number, total: number];
  mountSelect: [id: string];
  mountPoint: [id: string | undefined];
  // The rig pieces and attachments left off the figure, by path: their mount
  // is not in the rig of the piece they hang from.
  unplaced: [paths: string[]];
  // The painted rig pieces and attachments drawn from their plain holo
  // instead, by path: they did not load.
  fellBack: [paths: string[]];
  // Loading parts, a character or a paint after the model itself.
  busy: [busy: boolean];
}>();

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

// Whether these parts landed; a newer request supersedes them otherwise.
const attachMounts = (scene: Group) => whileBusy(attachMountsNow(scene));

const attachMountsNow = async (scene: Group) => {
  const request = ++mountsRequest;
  const mounts = props.model.mounts;
  const next = mounts?.length ? await buildMounts(mounts) : undefined;

  if (request !== mountsRequest) return false;

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

  return true;
};

// The renderer refreshes a skeleton only when it draws; measured before the
// first frame, a skinned figure would read as its bind pose.
const refreshSkeletons = (scene: Group) => {
  scene.updateMatrixWorld(true);
  scene.traverse((node) => {
    if ((node as SkinnedMesh).isSkinnedMesh) {
      (node as SkinnedMesh).skeleton.update();
    }
  });
};

// The game's own lights for the figure, in its frame.
let rigLights: Group | undefined;

const placeRigLights = (scene: Group) => {
  if (rigLights) scene.remove(rigLights);
  rigLights = undefined;

  const lights = props.model.rig?.lights ?? [];
  if (!lights.length) return;

  rigLights = buildRigLights(lights);
  scene.add(rigLights);
  invalidate();
};

// Stands under a rigged figure; measured with it, so the camera frames both.
let pedestal: Group | undefined;

// Worn pieces skinned to the root's skeleton, bound to its bones under one
// group so a change of outfit swaps them in place.
let rigRoot: Group | undefined;
let rigRequest = 0;
let rigClips: AnimationClip[] = [];

// The character on the body: what it loaded, and how to put the body's own
// head and skin back.
let character: LoadedCharacter | undefined;
let undressHead: (() => void) | undefined;
let undressNeck: (() => void) | undefined;

// Hats moved onto the face for the figure as it is drawn now.
let fittedGeometries: BufferGeometry[] = [];

// A character loads in the background: the figure is shown at once, with the
// character it had or none, and dressed again once the new one is in. The
// same character on a changed outfit is kept: baking its head again would
// stall every change.
let characterLoading: string | undefined;
let readyCharacter: LoadedCharacter | undefined;

const characterKey = (key: string) =>
  `${key}|${!!props.model.textured}|${!!props.model.rig?.environment}`;

const characterFor = (scene: Group) => {
  const wanted = props.model.rig?.character;
  if (!wanted) return undefined;

  const key = characterKey(wanted.key);
  for (const candidate of [character, readyCharacter]) {
    if (
      candidate &&
      characterKey(candidate.key) === key &&
      candidate.textured === !!props.model.textured
    ) {
      return candidate;
    }
  }

  if (characterLoading !== key) {
    characterLoading = key;
    void whileBusy(
      loadCharacter(
        wanted,
        !!props.model.textured,
        !!props.model.rig?.environment,
      )
        .catch((error) => {
          console.warn("The character did not load", error);
          return undefined;
        })
        .then((loaded) => {
          if (characterLoading === key) characterLoading = undefined;
          if (!loaded) return;

          const still = props.model.rig?.character;
          if (unmounted || !still || characterKey(still.key) !== key) {
            disposeCharacter(loaded);
            return;
          }

          if (readyCharacter && readyCharacter !== character) {
            disposeCharacter(readyCharacter);
          }
          readyCharacter = loaded;
          void attachRig(scene);
        }),
    );
  }

  // Until it is in, the one already on the figure stands in.
  return character;
};

// The body's own skinned parts, each with the region it covers: hidden under
// an undersuit or a helmet that hides the head.
const hideCovered = (scene: Group) => {
  const parts: SkinnedMesh[] = [];
  scene.traverse((node) => {
    const mesh = node as SkinnedMesh;
    if (mesh.isSkinnedMesh && !withinRig(mesh)) parts.push(mesh);
  });

  // The body's bind-pose height, its stored points being Z up.
  let height = 0;
  parts.forEach((part) => {
    if (/head|eyes|teeth/i.test(part.name)) return;
    part.geometry.computeBoundingBox();
    height = Math.max(height, part.geometry.boundingBox?.max.z ?? 0);
  });

  const hidden = new Set(props.model.rig?.hide ?? []);
  parts.forEach((part) => {
    part.userData.region ??= bodyRegion(part, height || 1);
    part.visible = !hidden.has(part.userData.region);
  });

  invalidate();
};

const withinRig = (node: Object3D) => {
  for (let current: Object3D | null = node; current; current = current.parent) {
    if (current === rigRoot) return true;
  }

  return false;
};

const pose = (scene: Group) => {
  // Its cached bindings and actions go with it, or every pose tried stays.
  mixer.value?.stopAllAction();
  mixer.value?.uncacheRoot(scene);
  mixer.value = undefined;

  const wanted = props.model.rig?.clip;
  const clip =
    rigClips.find((candidate) => candidate.name === wanted) ?? rigClips[0];
  if (!clip) return;

  mixer.value = new AnimationMixer(scene);
  mixer.value.clipAction(clip).play();
  mixer.value.update(0);
  refreshSkeletons(scene);
  invalidate();
};

// A rigid item's holo, turned into its bone's axes; its plain holo when the
// painted one does not load, and nothing when neither does.
const loadAttachment = async (attachment: RigAttachment) => {
  const load = (path: string) =>
    loadHolo(path).then((holo) => {
      // The holos and the rig share the export's frame, so a holo sits on
      // its bone as it is -- moved so its helper, where it has one, is the
      // point that meets the bone.
      const group = new Group();
      const item = cloneShared(holo);
      if (attachment.helper) {
        item.applyMatrix4(
          new Matrix4()
            .compose(
              new Vector3().fromArray(attachment.helper.position),
              new Quaternion().fromArray(attachment.helper.rotation),
              new Vector3(1, 1, 1),
            )
            .invert(),
        );
      }
      group.add(item);
      return group;
    });

  try {
    const group = await load(attachment.path);
    group.userData.textured = !!attachment.textured;
    return {
      group,
      path: attachment.path,
      bone: attachment.bone,
      from: attachment.from,
      textured: !!attachment.textured,
    };
  } catch (error) {
    if (!attachment.fallbackPath) {
      console.warn("An attached part did not load", error);
      return undefined;
    }
  }

  try {
    return {
      group: await load(attachment.fallbackPath),
      path: attachment.path,
      bone: attachment.bone,
      from: attachment.from,
      textured: false,
    };
  } catch (error) {
    console.warn("An attached part did not load", error);
    return undefined;
  }
};

// A worn piece's rig; its plain rig when the painted one does not load, and
// nothing when neither does.
const loadRigPiece = async (piece: RigPiece) => {
  try {
    return {
      scene: cloneRigPiece(await loadHolo(piece.path)),
      textured: !!piece.textured,
    };
  } catch (error) {
    if (!piece.fallbackPath) {
      console.warn("A rigged part did not load", error);
      return undefined;
    }
  }

  try {
    return {
      scene: cloneRigPiece(await loadHolo(piece.fallbackPath)),
      textured: false,
    };
  } catch (error) {
    console.warn("A rigged part did not load", error);
    return undefined;
  }
};

// Whether these pieces landed; a newer request supersedes them otherwise.
const attachRig = (scene: Group) => whileBusy(attachRigNow(scene));

const attachRigNow = async (scene: Group) => {
  const request = ++rigRequest;
  const rig = props.model.rig;
  if (!rig) return true;

  const [pieces, attachments, clips] = await Promise.all([
    Promise.all(rig.pieces.map(loadRigPiece)),
    Promise.all((rig.attachments ?? []).map(loadAttachment)),
    rig.animations
      ? loadClips(rig.animations).catch(() => [] as AnimationClip[])
      : Promise.resolve([] as AnimationClip[]),
  ]);

  if (request !== rigRequest) {
    return false;
  }

  const fellBack = [
    ...rig.pieces.filter(
      (piece, index) => piece.textured && pieces[index]?.textured === false,
    ),
    ...(rig.attachments ?? []).filter(
      (attachment, index) =>
        attachment.textured && attachments[index]?.textured === false,
    ),
  ].map((part) => part.path);
  if (fellBack.length) emit("fellBack", fellBack);

  if (rigRoot) {
    scene.remove(rigRoot);
    [
      ...(rigRoot.userData.attached as Object3D[]),
      ...(rigRoot.userData.grafted as Object3D[]),
    ].forEach((node) => node.removeFromParent());
  }

  undressNeck?.();
  undressNeck = undefined;
  undressHead?.();
  undressHead = undefined;
  const loadedCharacter = characterFor(scene);
  if (character && character !== loadedCharacter) disposeCharacter(character);
  if (readyCharacter === loadedCharacter) readyCharacter = undefined;
  character = loadedCharacter;

  fittedGeometries.forEach((geometry) => geometry.dispose());
  fittedGeometries = [];
  const fitted: BufferGeometry[] = [];

  if (character && rig.character) {
    const faceWrap = new Set(rig.character.faceWrap);
    pieces.forEach((piece, index) => {
      if (piece && faceWrap.has(rig.pieces[index]?.path ?? "")) {
        fitted.push(...fitPieceToFace(piece.scene, character!));
      }
    });
    fittedGeometries = fitted;
    undressHead = dressHead(
      scene,
      character,
      rig.character,
      !!props.model.textured,
    );
  }

  if (rig.collar) undressNeck = dressNeck(scene, rig.collar === "hood");

  const bones = bonesByName(scene);
  const next = new Group();
  next.userData.grafted = [];
  next.userData.attached = [];
  const unplaced: string[] = [];

  pieces.forEach((piece, index) => {
    if (!piece) return;

    const { meshes, grafted } = bindToBones(piece.scene, bones, {
      hangs: rig.pieces[index]?.hangs,
      from: rig.pieces[index]?.from,
      source: rig.pieces[index]?.path,
    });
    meshes.forEach((mesh) => {
      mesh.userData.textured = piece.textured;
    });
    if (meshes.length) next.add(...meshes);
    else if (rig.pieces[index]) unplaced.push(rig.pieces[index].path);
    next.userData.grafted.push(...grafted);
  });

  // The character's hair, brows, beard and piercings, on the body's own
  // skeleton like the pieces.
  character?.accessories.forEach((accessory) => {
    const { meshes, grafted } = bindToBones(cloneRigPiece(accessory), bones);
    if (meshes.length) next.add(...meshes);
    next.userData.grafted.push(...grafted);
  });

  // After the pieces: a holster or a weapon mount is a bone a piece brings,
  // and the map holds the outermost piece's copy of each.
  attachments.forEach((attachment) => {
    if (!attachment) return;

    const bone = bones.get(attachment.bone);
    if (
      !bone ||
      (attachment.from && bone.userData.source !== attachment.from)
    ) {
      unplaced.push(attachment.path);
      return;
    }

    bone.add(attachment.group);
    next.userData.attached.push(attachment.group);
    if (!attachment.textured) setMaterials(attachment.group);
  });

  scene.add(next);

  // In the studio the key light casts a soft shadow: everything opaque casts
  // and takes it, see-through hair caps only take it.
  if (rig.environment) {
    scene.traverse((node) => {
      const mesh = node as Mesh;
      if (!mesh.isMesh) return;
      const materials = [mesh.material].flat() as Material[];
      mesh.castShadow = !materials.some((material) => material.transparent);
      mesh.receiveShadow = true;
    });
  }
  rigRoot = next;
  rigClips = clips;

  // On a painted body too: only the painted pieces keep their own materials.
  setMaterials(next);

  hideCovered(scene);
  pose(scene);
  emit("unplaced", unplaced);

  return true;
};

// The part under the pointer, looked for among the mounted parts alone: on a
// see-through hull the part shows through it, and a click on it should reach
// it rather than the hull in front.
const raycaster = new Raycaster();
const pointer = new Vector2();

const mountAt = (event: PointerEvent | MouseEvent) => {
  const canvas = renderer.domElement;
  if (!mountRoot || !camera.value) return undefined;

  const rect = canvas.getBoundingClientRect();
  pointer.set(
    ((event.clientX - rect.left) / rect.width) * 2 - 1,
    -((event.clientY - rect.top) / rect.height) * 2 + 1,
  );
  raycaster.setFromCamera(pointer, camera.value);

  const hit = raycaster
    .intersectObject(mountRoot, true)
    .find(
      ({ object }) =>
        (object as Mesh).isMesh && !object.userData.overlay && object.visible,
    );

  // A part with no slot of its own, a default gun on its mount, stands for
  // the slot it hangs from.
  for (let node = hit?.object ?? null; node; node = node.parent) {
    if (node.userData.mountId) return node.userData.mountId as string;
  }

  return undefined;
};

let pointed: string | undefined;

const onPointerMove = (event: PointerEvent) => {
  const id = event.buttons ? undefined : mountAt(event);

  renderer.domElement.style.cursor = id ? "pointer" : "";
  if (id === pointed) return;

  pointed = id;
  emit("mountPoint", id);
};

const onPointerLeave = () => {
  renderer.domElement.style.cursor = "";
  if (!pointed) return;

  pointed = undefined;
  emit("mountPoint", undefined);
};

// A drag turns the holo; only a press released where it began is a click.
const DRAG_TOLERANCE = 4;
let pressedAt: [number, number] | undefined;

const onPointerDown = (event: PointerEvent) => {
  pressedAt = [event.clientX, event.clientY];
};

const onClick = (event: MouseEvent) => {
  if (
    !pressedAt ||
    Math.hypot(event.clientX - pressedAt[0], event.clientY - pressedAt[1]) >
      DRAG_TOLERANCE
  ) {
    return;
  }

  const id = mountAt(event);
  if (id) emit("mountSelect", id);
};

if (props.pickable) {
  const canvas = renderer.domElement;
  canvas.addEventListener("pointermove", onPointerMove);
  canvas.addEventListener("pointerleave", onPointerLeave);
  canvas.addEventListener("pointerdown", onPointerDown);
  canvas.addEventListener("click", onClick);

  onUnmounted(() => {
    canvas.removeEventListener("pointermove", onPointerMove);
    canvas.removeEventListener("pointerleave", onPointerLeave);
    canvas.removeEventListener("pointerdown", onPointerDown);
    canvas.removeEventListener("click", onClick);
    canvas.style.cursor = "";
  });
}

// The export's own paint, kept to switch back to.
type OwnPaint = {
  map: Texture | null;
  orm: Texture | null;
  roughness: number;
  metalness: number;
};

// A material's own maps under a paint. Not in userData, which three copies
// through JSON when it clones a material: the copy would come back as plain
// objects where textures belong.
const ownPaints = new WeakMap<Material, OwnPaint>();

let paintMaps: Texture[] = [];
let paintRequest = 0;

const loadPaintMap = (url?: string) =>
  url
    ? new TextureLoader(extrasLoadingManager)
        .loadAsync(url)
        .catch(() => undefined)
    : Promise.resolve(undefined);

const applyPaint = (scene: Group) => whileBusy(applyPaintNow(scene));

const applyPaintNow = async (scene: Group) => {
  const request = ++paintRequest;
  const [map, loadedOrm, loadedStencil] = await Promise.all([
    loadPaintMap(props.model.paint),
    loadPaintMap(props.model.paint && props.model.paintOrm),
    loadPaintMap(props.model.paint && props.model.paintStencil),
  ]);

  // Only with their own base colour: a metal paint's ORM under another paint's
  // colours would turn the wrong parts to metal, and its artwork would sit on
  // the wrong paint.
  const orm = map ? loadedOrm : undefined;
  const stencil = map ? loadedStencil : undefined;
  if (!orm) loadedOrm?.dispose();
  if (!stencil) loadedStencil?.dispose();

  if (request !== paintRequest) {
    map?.dispose();
    orm?.dispose();
    stencil?.dispose();
    return;
  }

  applyStencilMap(scene, stencil);

  partMaterials(scene, BODY_SUFFIX).forEach((bodyMaterial) => {
    let own = ownPaints.get(bodyMaterial);
    if (!own) {
      own = {
        map: bodyMaterial.map,
        orm: bodyMaterial.roughnessMap,
        roughness: bodyMaterial.roughness,
        metalness: bodyMaterial.metalness,
      };
      ownPaints.set(bodyMaterial, own);
    }

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
  paintMaps = [map, orm, stencil].filter((paintMap) => paintMap !== undefined);

  invalidate();
};

const setup = async (scene: Group, animations: AnimationClip[]) => {
  if (props.model.textured) {
    playAnimations(scene, animations);
    if (props.model.paint) void applyPaint(scene);
  } else {
    setMaterials(scene);
  }

  // Parts in one shared frame, a figure dressed from its pieces, are framed
  // and centred together: the root alone may be any one of them.
  if (props.model.rig) {
    // Shown once it is dressed and posed, rather than bare in its bind pose
    // while the pieces and clips load.
    scene.visible = false;
    try {
      scene.traverse((node) => {
        // Posed away from the bind pose, the stored bounds no longer hold.
        if ((node as Mesh).isMesh) node.frustumCulled = false;
      });
      while (!unmounted && !(await attachRig(scene)));

      placeRigLights(scene);

      if (props.model.rig.pedestal && !pedestal) {
        pedestal = buildPedestal(
          new Box3().setFromObject(scene, true),
          props.color,
        );
        pedestal.visible = !props.fullscreen;
        scene.add(pedestal);
      }
    } finally {
      scene.visible = true;
    }
  }

  // Asked again until the parts it frames are the ones that landed: a fitting
  // changed while they loaded would leave it framing the root alone.
  if (props.model.frameMounts) {
    while (!unmounted && !(await attachMounts(scene)));
  }

  // A skinned figure is measured where its bones put it: its stored
  // positions are the bind pose, in the export's own frame.
  const precise = !!props.model.rig;
  const box = new Box3().setFromObject(scene, precise);
  const size = box.getSize(new Vector3());

  if (props.onGrid && props.model.length) {
    const scale = gridScale(size, props.model.length);
    scene.scale.setScalar(scale);
    size.multiplyScalar(scale);
  }

  scene.updateMatrixWorld(true);
  const scaledBox = new Box3().setFromObject(scene, precise);
  const center = scaledBox.getCenter(new Vector3());
  scene.position.sub(center);

  if (props.offsetModel?.length) {
    scene.position.y += props.offsetModel.length;
  }

  if (props.model.rig) refreshSkeletons(scene);

  emit("loaded", size, scene);

  if (!props.model.frameMounts) void attachMounts(scene);
};

watch(
  () => state.value,
  () => {
    if (state.value) {
      void setup(state.value.scene, state.value.animations);
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

watch(
  () => rigLayoutKey(props.model.rig),
  () => {
    if (state.value) void attachRig(state.value.scene);
  },
);

watch(
  () => (props.model.rig?.hide ?? []).join(","),
  () => {
    if (state.value && rigRoot) hideCovered(state.value.scene);
  },
);

watch(
  () => props.model.rig?.clip,
  () => {
    if (state.value && rigRoot) pose(state.value.scene);
  },
);

watch(
  () => props.fullscreen,
  (fullscreen) => {
    if (!pedestal) return;

    pedestal.visible = !fullscreen;
    invalidate();
  },
);

watch(
  () => rigLightsKey(props.model.rig),
  () => {
    if (state.value && props.model.rig) placeRigLights(state.value.scene);
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

// By value: an array built afresh on every read would fire on any change of
// the model, and re-paint a figure that has no paint at all.
watch(
  () =>
    [props.model.paint, props.model.paintOrm, props.model.paintStencil].join(
      "|",
    ),
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
