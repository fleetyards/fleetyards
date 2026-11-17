<script lang="ts">
export default {
  name: "StarmapScene",
};
</script>

<script lang="ts" setup>
import {
  AmbientLight,
  Color,
  DirectionalLight,
  Group,
  Matrix4,
  Mesh,
  MeshBasicMaterial,
  MeshLambertMaterial,
  PerspectiveCamera,
  SphereGeometry,
  Vector2,
  Vector3,
  type Material,
} from "three";
import { Line2 } from "three/examples/jsm/lines/Line2.js";
import { LineGeometry } from "three/examples/jsm/lines/LineGeometry.js";
import { LineMaterial } from "three/examples/jsm/lines/LineMaterial.js";
import { useLoop, useTres } from "@tresjs/core";
import { Html } from "@tresjs/cientos";
import StarmapLabel from "./Label.vue";
import type { StarmapItem, StarmapRole, StarmapScene } from "./layout";

type Props = {
  scene: StarmapScene;
  // What the camera frames: a new level is framed afresh, while a scene that
  // only changes because more data arrived keeps the reader's view.
  levelKey: string;
  selectedKey: string | null;
};

const props = defineProps<Props>();

const emit = defineEmits<{
  select: [item: StarmapItem | null];
  enter: [item: StarmapItem];
}>();

const { camera, controls, renderer } = useTres();
const { onBeforeRender } = useLoop();

// The smallest a thing is drawn, in pixels across: at true scale a planet is a
// thousandth of a unit in its system and would never be seen.
const MIN_PIXELS: Record<StarmapRole, number> = {
  system: 16,
  star: 18,
  planet: 10,
  moon: 8,
  place: 4,
};

// How near the pointer has to come to a thing to pick it, in pixels.
const PICK_PIXELS = 12;
const TIE_PIXELS = 3;

const sphere = new SphereGeometry(1, 48, 32);
const group = new Group();
const meshes = new Map<string, Mesh>();
const lineMaterials: LineMaterial[] = [];

const disposeGroup = () => {
  group.traverse((object) => {
    if (object instanceof Mesh) {
      if (object.geometry !== sphere) object.geometry.dispose();
      (object.material as Material).dispose();
    }
  });
  group.clear();
  meshes.clear();
  lineMaterials.length = 0;
};

// Lines a pixel and a half wide whatever the screen's pixel ratio: a plain
// three.js line is one device pixel, which a high-density screen all but
// loses.
const line = (
  points: number[],
  { opacity, dashed = false }: { opacity: number; dashed?: boolean },
) => {
  const geometry = new LineGeometry();
  geometry.setPositions(points);

  const material = new LineMaterial({
    color: 0x5aafd4,
    linewidth: 1.5,
    transparent: true,
    opacity,
    dashed,
    dashScale: 1,
    dashSize: 0.8,
    gapSize: 0.6,
  });
  lineMaterials.push(material);

  const object = new Line2(geometry, material);
  object.computeLineDistances();
  return object;
};

const circle = (radius: number) => {
  const points: number[] = [];
  for (let step = 0; step <= 128; step += 1) {
    const angle = (step / 128) * Math.PI * 2;
    points.push(Math.cos(angle) * radius, 0, Math.sin(angle) * radius);
  }
  return points;
};

const BODY_ROLES = new Set<StarmapRole>(["planet", "moon"]);

const build = (scene: StarmapScene) => {
  disposeGroup();

  for (const radius of scene.orbits) {
    group.add(line(circle(radius), { opacity: 0.45 }));
  }

  for (const link of scene.links) {
    group.add(
      line([...link.from, ...link.to], {
        opacity: link.temporary ? 0.55 : 0.8,
        dashed: link.temporary,
      }),
    );
  }

  // Close up a body is a sphere, so it is lit from its star; everywhere else
  // things are dots and stay flat.
  if (scene.sun) {
    const light = new DirectionalLight(0xffffff, 2.4);
    light.position.set(...scene.sun).normalize();
    group.add(light, new AmbientLight(0xffffff, 0.5));
  }

  for (const entry of scene.items) {
    const color = new Color(entry.color);
    const material =
      scene.sun && BODY_ROLES.has(entry.role)
        ? new MeshLambertMaterial({ color })
        : new MeshBasicMaterial({
            color,
            transparent: entry.role === "place",
            opacity: entry.role === "place" ? 0.9 : 1,
          });
    const mesh = new Mesh(sphere, material);
    mesh.position.set(...entry.position);
    mesh.userData.key = entry.key;
    group.add(mesh);
    meshes.set(entry.key, mesh);
  }
};

// --- Camera ---

const goal = {
  target: new Vector3(),
  position: new Vector3(),
  active: false,
};

const frame = (scene: StarmapScene) => {
  const extent = scene.extent;
  goal.target.set(0, 0, 0);
  goal.position.set(0, extent * 0.6, extent * 1.1);

  const cam = camera.value;
  if (cam instanceof PerspectiveCamera) {
    cam.near = extent / 10000;
    cam.far = Math.max(extent, scene.reach) * 40;
    cam.updateProjectionMatrix();
  }

  goal.active = true;
};

const flyTo = (entry: StarmapItem) => {
  const cam = camera.value;
  const target = controlsTarget();
  if (!cam || !target) return;

  const offset = cam.position.clone().sub(target);
  const point = new Vector3(...entry.position);
  const distance = entry.radius
    ? Math.max(entry.radius * 8, props.scene.extent * 0.05)
    : Math.max(offset.length() * 0.5, props.scene.extent * 0.05);

  goal.target.copy(point);
  goal.position.copy(point).add(offset.setLength(distance));
  goal.active = true;
};

const controlsTarget = (): Vector3 | undefined =>
  (controls.value as { target?: Vector3 } | null)?.target;

const hidden = shallowRef<Set<string>>(new Set());

// Labels are only laid out again when the view moved, the canvas was resized
// or the scene or selection changed: not on every frame of an idle map.
let dirty = true;
const lastView = { matrix: new Matrix4(), width: 0, height: 0 };

const viewChanged = (cam: PerspectiveCamera, element: HTMLCanvasElement) => {
  const changed =
    dirty ||
    !lastView.matrix.equals(cam.matrixWorld) ||
    lastView.width !== element.clientWidth ||
    lastView.height !== element.clientHeight;

  if (changed) {
    lastView.matrix.copy(cam.matrixWorld);
    lastView.width = element.clientWidth;
    lastView.height = element.clientHeight;
    dirty = false;
  }

  return changed;
};

watch(
  () => props.scene,
  (scene) => {
    build(scene);
    dirty = true;
  },
  { immediate: true },
);

watch(
  () => props.levelKey,
  () => frame(props.scene),
  { immediate: true },
);

watch(
  () => props.selectedKey,
  () => {
    dirty = true;
  },
);

// --- Per frame ---

const world = new Vector3();
const projected = new Vector3();
const resolution = new Vector2();
const toPoint = new Vector3();
const closest = new Vector3();

// Whether the body at the centre stands between the camera and a point: what
// is on its far side is neither labelled nor picked.
const occluded = (point: Vector3, from: Vector3) => {
  const radius = props.scene.occluder;
  if (!radius) return false;

  toPoint.copy(point).sub(from);
  const t = -from.dot(toPoint) / toPoint.lengthSq();
  if (t <= 0 || t >= 1) return false;

  closest.copy(from).addScaledVector(toPoint, t);
  return closest.length() < radius * 0.995;
};

onBeforeRender(() => {
  const cam = camera.value;
  if (!(cam instanceof PerspectiveCamera)) return;

  const target = controlsTarget();

  if (goal.active && target) {
    cam.position.lerp(goal.position, 0.12);
    target.lerp(goal.target, 0.12);
    (controls.value as { update?: () => void } | null)?.update?.();

    if (
      cam.position.distanceTo(goal.position) < props.scene.extent * 1e-4 &&
      target.distanceTo(goal.target) < props.scene.extent * 1e-4
    ) {
      goal.active = false;
    }
  }

  const element = canvas();
  const height = element?.clientHeight || 1;

  if (element) {
    resolution.set(element.clientWidth, element.clientHeight);
    for (const material of lineMaterials) material.resolution.copy(resolution);
  }

  const perPixel = (2 * Math.tan((cam.fov * Math.PI) / 360)) / height;

  for (const entry of props.scene.items) {
    const mesh = meshes.get(entry.key);
    if (!mesh) continue;

    mesh.getWorldPosition(world);
    const minimum =
      (MIN_PIXELS[entry.role] / 2) * perPixel * cam.position.distanceTo(world);
    const selected = entry.key === props.selectedKey ? 1.4 : 1;

    mesh.scale.setScalar(Math.max(entry.radius ?? 0, minimum) * selected);
  }

  if (element && viewChanged(cam, element)) declutter(cam, element);
});

// --- Picking ---

const canvas = (): HTMLCanvasElement | null => {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const instance = renderer as any;
  return instance?.domElement ?? instance?.value?.domElement ?? null;
};

const pick = (event: PointerEvent | MouseEvent): StarmapItem | null => {
  const element = canvas();
  const cam = camera.value;
  if (!element || !cam) return null;

  const rect = element.getBoundingClientRect();
  let best: StarmapItem | null = null;
  let bestDistance = Infinity;

  for (const entry of props.scene.items) {
    const mesh = meshes.get(entry.key);
    if (!mesh) continue;

    if (occluded(mesh.position, cam.position)) continue;

    projected.copy(mesh.position).project(cam);
    if (projected.z > 1) continue;

    const x = ((projected.x + 1) / 2) * rect.width + rect.left;
    const y = ((1 - projected.y) / 2) * rect.height + rect.top;
    const distance = Math.hypot(x - event.clientX, y - event.clientY);

    if (distance >= PICK_PIXELS) continue;

    // Dots a few pixels apart are one spot to the pointer: the place that
    // matters more wins, as its label did.
    const closer = distance < bestDistance - TIE_PIXELS;
    const tied = Math.abs(distance - bestDistance) <= TIE_PIXELS;

    if (!best || closer || (tied && entry.rank < best.rank)) {
      best = entry;
      bestDistance = distance;
    }
  }

  return best;
};

const pressed = { x: 0, y: 0 };

const onPointerDown = (event: PointerEvent) => {
  pressed.x = event.clientX;
  pressed.y = event.clientY;
  goal.active = false;
};

// A drag turns the view; only a click picks.
const onPointerUp = (event: PointerEvent) => {
  if (Math.hypot(event.clientX - pressed.x, event.clientY - pressed.y) > 4) {
    return;
  }

  const entry = pick(event);
  emit("select", entry);
  if (entry) flyTo(entry);
};

const onDoubleClick = (event: MouseEvent) => {
  const entry = pick(event);
  if (entry?.enterable) emit("enter", entry);
};

const onWheel = () => {
  goal.active = false;
};

let bound: HTMLCanvasElement | null = null;

const bind = () => {
  const element = canvas();
  if (!element || element === bound) return;

  element.addEventListener("pointerdown", onPointerDown);
  element.addEventListener("pointerup", onPointerUp);
  element.addEventListener("dblclick", onDoubleClick);
  element.addEventListener("wheel", onWheel, { passive: true });
  bound = element;
};

const unbind = () => {
  if (!bound) return;

  bound.removeEventListener("pointerdown", onPointerDown);
  bound.removeEventListener("pointerup", onPointerUp);
  bound.removeEventListener("dblclick", onDoubleClick);
  bound.removeEventListener("wheel", onWheel);
  bound = null;
};

// The canvas is only there once the renderer is: bind on the first frame that
// has it, then stop looking.
onMounted(bind);
const { off: stopBinding } = onBeforeRender(() => {
  bind();
  if (bound) stopBinding();
});

onBeforeUnmount(() => {
  unbind();
  disposeGroup();
  sphere.dispose();
});

const LABEL_HEIGHT = 14;
const LABEL_CHAR_WIDTH = 6.5;

const declutter = (cam: PerspectiveCamera, element: HTMLCanvasElement) => {
  const width = element.clientWidth;
  const height = element.clientHeight;

  const candidates = props.scene.items
    .filter((entry) => entry.labelled || entry.key === props.selectedKey)
    .sort((a, b) => {
      if (a.key === props.selectedKey) return -1;
      if (b.key === props.selectedKey) return 1;
      return a.rank - b.rank;
    });

  const placed: { x: number; y: number; half: number }[] = [];
  const next = new Set<string>();

  for (const entry of candidates) {
    projected.set(...entry.position);
    const behind = occluded(projected, cam.position);
    projected.project(cam);

    if ((behind || projected.z > 1) && entry.key !== props.selectedKey) {
      next.add(entry.key);
      continue;
    }

    const x = ((projected.x + 1) / 2) * width;
    const y = ((1 - projected.y) / 2) * height;
    const half = (entry.name.length * LABEL_CHAR_WIDTH) / 2;

    const overlaps = placed.some(
      (other) =>
        Math.abs(other.x - x) < other.half + half &&
        Math.abs(other.y - y) < LABEL_HEIGHT,
    );

    if (overlaps && entry.key !== props.selectedKey) {
      next.add(entry.key);
    } else {
      placed.push({ x, y, half });
    }
  }

  const changed =
    next.size !== hidden.value.size ||
    [...next].some((key) => !hidden.value.has(key));

  if (changed) hidden.value = next;
};

const labelled = computed(() =>
  props.scene.items.filter(
    (entry) =>
      (entry.labelled || entry.key === props.selectedKey) &&
      !hidden.value.has(entry.key),
  ),
);

defineExpose({ flyTo, frame: () => frame(props.scene) });
</script>

<template>
  <primitive :object="group" />

  <Html
    v-for="entry in labelled"
    :key="entry.key"
    :position="entry.position"
    center
    pointer-events="none"
    :z-index-range="[1, 10]"
  >
    <StarmapLabel
      :name="entry.name"
      :role="entry.role"
      :selected="entry.key === selectedKey"
    />
  </Html>
</template>
