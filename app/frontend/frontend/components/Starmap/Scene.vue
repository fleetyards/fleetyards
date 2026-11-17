<script lang="ts">
export default {
  name: "StarmapScene",
};
</script>

<script lang="ts" setup>
import {
  BufferGeometry,
  Color,
  Group,
  LineBasicMaterial,
  LineDashedMaterial,
  LineLoop,
  LineSegments,
  Mesh,
  MeshBasicMaterial,
  PerspectiveCamera,
  SphereGeometry,
  Vector3,
} from "three";
import { useLoop, useTres } from "@tresjs/core";
import { Html } from "@tresjs/cientos";
import StarmapLabel from "./Label.vue";
import type { StarmapItem, StarmapRole, StarmapScene } from "./layout";

type Props = {
  scene: StarmapScene;
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

const sphere = new SphereGeometry(1, 24, 16);
const group = new Group();
const meshes = new Map<string, Mesh>();

const disposeGroup = () => {
  group.traverse((object) => {
    if (object instanceof Mesh || object instanceof LineLoop) {
      if (object.geometry !== sphere) object.geometry.dispose();
      (object.material as MeshBasicMaterial).dispose();
    }
  });
  group.clear();
  meshes.clear();
};

const circle = (radius: number) => {
  const points: Vector3[] = [];
  for (let step = 0; step < 128; step += 1) {
    const angle = (step / 128) * Math.PI * 2;
    points.push(
      new Vector3(Math.cos(angle) * radius, 0, Math.sin(angle) * radius),
    );
  }
  return new BufferGeometry().setFromPoints(points);
};

const build = (scene: StarmapScene) => {
  disposeGroup();

  for (const radius of scene.orbits) {
    group.add(
      new LineLoop(
        circle(radius),
        new LineBasicMaterial({
          color: 0x5aafd4,
          transparent: true,
          opacity: 0.35,
        }),
      ),
    );
  }

  for (const link of scene.links) {
    const line = new LineSegments(
      new BufferGeometry().setFromPoints([
        new Vector3(...link.from),
        new Vector3(...link.to),
      ]),
      link.temporary
        ? new LineDashedMaterial({
            color: 0x5aafd4,
            dashSize: 0.8,
            gapSize: 0.6,
            transparent: true,
            opacity: 0.5,
          })
        : new LineBasicMaterial({
            color: 0x5aafd4,
            transparent: true,
            opacity: 0.7,
          }),
    );
    line.computeLineDistances();
    group.add(line);
  }

  for (const entry of scene.items) {
    const mesh = new Mesh(
      sphere,
      new MeshBasicMaterial({
        color: new Color(entry.color),
        transparent: entry.role === "place",
        opacity: entry.role === "place" ? 0.85 : 1,
      }),
    );
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
    cam.far = extent * 100;
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

watch(
  () => props.scene,
  (scene) => {
    build(scene);
    frame(scene);
  },
  { immediate: true },
);

// --- Per frame ---

const world = new Vector3();
const projected = new Vector3();

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

  const height = canvas()?.clientHeight || 1;
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

  const element = canvas();
  if (element) declutter(cam, element);
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

    projected.copy(mesh.position).project(cam);
    if (projected.z > 1) continue;

    const x = ((projected.x + 1) / 2) * rect.width + rect.left;
    const y = ((1 - projected.y) / 2) * rect.height + rect.top;
    const distance = Math.hypot(x - event.clientX, y - event.clientY);

    if (distance < PICK_PIXELS && distance < bestDistance) {
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

onMounted(bind);
onBeforeRender(bind);

onBeforeUnmount(() => {
  unbind();
  disposeGroup();
  sphere.dispose();
});

// Which label gives way where two would overlap: the bodies keep theirs.
const RANK: Record<StarmapRole, number> = {
  system: 0,
  star: 0,
  planet: 1,
  moon: 2,
  place: 3,
};

const LABEL_HEIGHT = 14;
const LABEL_CHAR_WIDTH = 6.5;

const hidden = shallowRef<Set<string>>(new Set());

const declutter = (cam: PerspectiveCamera, element: HTMLCanvasElement) => {
  const width = element.clientWidth;
  const height = element.clientHeight;

  const candidates = props.scene.items
    .filter((entry) => entry.labelled || entry.key === props.selectedKey)
    .sort((a, b) => {
      if (a.key === props.selectedKey) return -1;
      if (b.key === props.selectedKey) return 1;
      return RANK[a.role] - RANK[b.role];
    });

  const placed: { x: number; y: number; half: number }[] = [];
  const next = new Set<string>();

  for (const entry of candidates) {
    projected.set(...entry.position).project(cam);

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
