<script lang="ts">
export default {
  name: "StarmapScene",
};
</script>

<script lang="ts" setup>
import {
  AmbientLight,
  Color,
  Group,
  Mesh,
  MeshBasicMaterial,
  MeshLambertMaterial,
  PerspectiveCamera,
  PointLight,
  SphereGeometry,
  SRGBColorSpace,
  TextureLoader,
  Vector2,
  Vector3,
  type Material,
  type Object3D,
  type Texture,
} from "three";
import { Line2 } from "three/examples/jsm/lines/Line2.js";
import { LineGeometry } from "three/examples/jsm/lines/LineGeometry.js";
import { LineMaterial } from "three/examples/jsm/lines/LineMaterial.js";
import { useLoop, useTres } from "@tresjs/core";
import { Html } from "@tresjs/cientos";
import StarmapLabel from "./Label.vue";
import { sun, surfaceTexture, type StarmapSun } from "./bodies";
import type { StarmapItem, StarmapRole, StarmapScene } from "./layout";

type Props = {
  scene: StarmapScene;
  // What the camera is on: it orbits this and every flight ends at it.
  focusKey: string | null;
};

const props = defineProps<Props>();

const emit = defineEmits<{
  // The reader picked something, or zoomed far enough out of what they were
  // on that the map stepped back out to what it belongs to.
  focus: [item: StarmapItem];
  // A system on the ring was opened.
  enter: [item: StarmapItem];
}>();

const { camera, controls, renderer } = useTres();
const { onBeforeRender } = useLoop();

// The smallest a thing is drawn, in pixels across: at true scale a planet seen
// from across its system is a fraction of a pixel.
const MIN_PIXELS: Record<StarmapRole, number> = {
  system: 18,
  star: 30,
  planet: 24,
  moon: 15,
  place: 5,
};

// How near the pointer has to come to a thing to pick it, in pixels, and how
// close two have to be to count as one spot.
const PICK_PIXELS = 14;
const TIE_PIXELS = 3;

// How long a flight takes, in seconds.
const FLIGHT_SECONDS = 1.3;

// One turn of a body's surface, as on the location pages.
const TURN_SECONDS = 90;

// What is near a body comes into view within this many of its radii, and is
// gone again at twice that. A moon is near its planet much further out.
const PLACES_NEAR = 14;
const MOONS_NEAR = 140;

const items = computed(() => props.scene.items);
const byKey = computed(
  () => new Map(props.scene.items.map((entry) => [entry.key, entry])),
);

// --- The world ---
//
// Everything is drawn around a floating origin: the world group is moved so
// that the point the camera orbits sits at zero. Positions stay exact in
// JavaScript's doubles, and the GPU only ever sees what is near the camera,
// so an outpost a few hundred metres off a planet sixty gigametres from its
// star does not shake.

const world = new Group();
const bodies = new Group();
world.add(bodies);

const origin = new Vector3();

// A body is seen close up; a place is a dot a few pixels across and needs a
// fraction of the triangles, which a system of eight hundred of them adds up.
const sphere = new SphereGeometry(1, 64, 32);
const dot = new SphereGeometry(1, 12, 8);
const meshes = new Map<string, Object3D>();
const fades = new Map<string, number>();
const lineMaterials: LineMaterial[] = [];
const orbitLines: { body: string; material: LineMaterial; base: number }[] = [];
const textures: Texture[] = [];
const suns: StarmapSun[] = [];

const LINE_COLOR = new Color(0x5aafd4);
// The stage's backdrop, near enough: a line is mixed against it rather than
// blended, since a translucent line draws its joints twice and they show as
// a string of brighter dots.
const BACKDROP = new Color(0x0a1626);

const lineColor = (amount: number, target = new Color()) =>
  target.lerpColors(BACKDROP, LINE_COLOR, amount);

// Lines a pixel and a half wide whatever the screen's pixel ratio: a plain
// three.js line is one device pixel, which a high-density screen all but
// loses.
const line = (
  points: number[],
  { amount, dashed = false }: { amount: number; dashed?: boolean },
) => {
  const geometry = new LineGeometry();
  geometry.setPositions(points);

  const material = new LineMaterial({
    color: lineColor(amount),
    linewidth: 1.5,
    dashed,
    dashScale: 1,
    dashSize: 0.8,
    gapSize: 0.6,
  });
  lineMaterials.push(material);

  const object = new Line2(geometry, material);
  object.computeLineDistances();
  return { object, material };
};

// Enough that the widest orbit on a wide screen still reads as a circle.
const ORBIT_STEPS = 512;

const circle = (radius: number) => {
  const points: number[] = [];
  for (let step = 0; step <= ORBIT_STEPS; step += 1) {
    const angle = (step / ORBIT_STEPS) * Math.PI * 2;
    points.push(Math.cos(angle) * radius, 0, Math.sin(angle) * radius);
  }
  return points;
};

const loader = new TextureLoader().setCrossOrigin("anonymous");
// Bumped on every rebuild, so a texture that arrives for a scene already torn
// down is thrown away rather than put on a disposed material.
let generation = 0;
// One load per surface: Pyro V and Ignis share theirs.
const gameSurfaces = new Map<string, Promise<Texture>>();

const gameSurface = (url: string) => {
  let pending = gameSurfaces.get(url);

  if (!pending) {
    pending = loader.loadAsync(url).then((texture) => {
      texture.colorSpace = SRGBColorSpace;
      texture.anisotropy = 4;
      textures.push(texture);
      return texture;
    });
    gameSurfaces.set(url, pending);
  }

  return pending;
};

// The game's own surface replaces the painted one once it has loaded; until
// then, or if it fails, the painted one stays.
const wrapInGameSurface = (material: MeshLambertMaterial, url: string) => {
  const built = generation;

  gameSurface(url)
    .then((texture) => {
      if (built !== generation) return;

      const painted = material.map;
      material.map = texture;
      material.needsUpdate = true;
      if (painted && painted !== texture) {
        painted.dispose();
        textures.splice(textures.indexOf(painted), 1);
      }
    })
    .catch(() => undefined);
};

const disposeBodies = () => {
  generation += 1;
  gameSurfaces.clear();
  bodies.traverse((object) => {
    if (object instanceof Mesh) {
      if (object.geometry !== sphere && object.geometry !== dot) {
        object.geometry.dispose();
      }
      (object.material as Material).dispose();
    }
  });
  for (const texture of textures) texture.dispose();
  for (const star of suns) star.dispose();
  bodies.clear();
  meshes.clear();
  fades.clear();
  lineMaterials.length = 0;
  orbitLines.length = 0;
  textures.length = 0;
  suns.length = 0;
};

const build = (scene: StarmapScene) => {
  disposeBodies();

  for (const orbit of scene.orbits) {
    const center = byKey.value.get(orbit.center);
    if (!center) continue;

    const base = byKey.value.get(orbit.body)?.role === "moon" ? 0.18 : 0.24;
    const { object, material } = line(circle(orbit.radius), { amount: base });
    // Drawn around its centre, so a moon's orbit stays exact next to its
    // planet rather than inheriting the planet's distance from the star.
    object.position.set(...center.position);
    orbitLines.push({ body: orbit.body, material, base });
    bodies.add(object);
  }

  for (const link of scene.links) {
    bodies.add(
      line([...link.from, ...link.to], {
        amount: link.temporary ? 0.3 : 0.45,
        dashed: link.temporary,
      }).object,
    );
  }

  if (scene.kind === "system") {
    bodies.add(new PointLight(0xffffff, 1.6, 0, 0));
  }
  // Enough that the night side still shows its surface: this is a map, and a
  // body half lost in the dark is half unreadable.
  bodies.add(new AmbientLight(0xffffff, 1.3));

  for (const entry of scene.items) {
    if (entry.role === "star") {
      const star = sun(entry.color, entry.unstable);
      star.object.position.set(...entry.position);
      suns.push(star);
      bodies.add(star.object);
      meshes.set(entry.key, star.object);
      continue;
    }

    let material: Material;

    if (entry.surface) {
      const map = surfaceTexture(entry.surface, entry.color, entry.slug);
      textures.push(map);
      const lambert = new MeshLambertMaterial({ map, transparent: true });
      material = lambert;
      if (entry.texture) wrapInGameSurface(lambert, entry.texture);
    } else {
      material = new MeshBasicMaterial({
        color: new Color(entry.color),
        transparent: true,
        opacity: 0.9,
      });
    }

    const mesh = new Mesh(entry.surface ? sphere : dot, material);
    mesh.position.set(...entry.position);
    bodies.add(mesh);
    meshes.set(entry.key, mesh);
  }
};

// --- Flying ---

const UP = new Vector3(0, 1, 0);

const vector = (entry: StarmapItem) => new Vector3(...entry.position);

const anchorOf = (entry: StarmapItem) =>
  entry.anchor ? byKey.value.get(entry.anchor) : undefined;

const overview = () => ({
  direction: new Vector3(0, 0.55, 1).normalize(),
  distance: props.scene.extent * 1.35,
});

// Where the camera sits for an item, as a direction from it and a distance.
const viewOf = (entry: StarmapItem, current: Vector3) => {
  if (entry.role === "system") {
    return { direction: current.clone(), distance: 9 };
  }

  if (entry.role === "star") return overview();

  const position = vector(entry);

  // A body is seen from its star's side and a little off it, so it shows its
  // day side with the night drawing in at one edge.
  if (entry.radius) {
    const towardStar = position.clone().negate().setY(0).normalize();
    const aside = new Vector3().crossVectors(UP, towardStar);

    return {
      direction: towardStar
        .multiplyScalar(0.8)
        .addScaledVector(aside, 0.55)
        .addScaledVector(UP, 0.5)
        .normalize(),
      distance: entry.radius * 3.4,
    };
  }

  // A place on or over a body is seen from above it.
  const anchor = anchorOf(entry);

  if (anchor?.radius && anchor.role !== "star") {
    const outward = position.clone().sub(vector(anchor)).normalize();

    return {
      direction: outward
        .multiplyScalar(0.8)
        .addScaledVector(current, 0.35)
        .normalize(),
      distance: anchor.radius * 0.5,
    };
  }

  return { direction: current.clone(), distance: 4 };
};

const flight = {
  active: false,
  elapsed: 0,
  fromOrigin: new Vector3(),
  toOrigin: new Vector3(),
  fromDistance: 1,
  toDistance: 1,
  fromDirection: new Vector3(),
  toDirection: new Vector3(),
};

// The key the camera last set out for, so a focus the scene asked for itself
// is not flown to a second time once it comes back as a prop.
let flownTo: string | null | undefined;

type Orbiting = {
  target?: Vector3;
  minDistance: number;
  maxDistance: number;
  update?: () => void;
};

const orbiting = () => controls.value as Orbiting | null;

// The distances the reader can zoom between around what is focused. Only set
// once a flight has landed: during one the camera passes nearer than the new
// focus allows, and the controls would clamp it off its path.
const limit = (entry: StarmapItem | undefined) => {
  const orbit = orbiting();
  if (!orbit) return false;

  orbit.minDistance = entry?.radius ? entry.radius * 1.08 : 0.0005;
  orbit.maxDistance = props.scene.extent * 4;
  return true;
};

const unlimit = () => {
  const orbit = orbiting();
  if (!orbit) return;

  orbit.minDistance = 0;
  orbit.maxDistance = Infinity;
};

let limited = false;

const flyTo = (
  entry: StarmapItem | undefined,
  { keepDistance = false }: { keepDistance?: boolean } = {},
) => {
  const cam = camera.value;
  if (!cam) return;

  const current = cam.position.clone().normalize();
  const view = entry ? viewOf(entry, current) : overview();

  flight.fromOrigin.copy(origin);
  flight.toOrigin.copy(entry ? vector(entry) : new Vector3());
  flight.fromDistance = Math.max(cam.position.length(), 1e-6);
  flight.toDistance = keepDistance ? flight.fromDistance : view.distance;
  flight.fromDirection.copy(current);
  flight.toDirection.copy(keepDistance ? current : view.direction);
  flight.elapsed = 0;
  flight.active = true;

  flownTo = entry?.key ?? null;
  limited = false;
  unlimit();
};

// A flight interrupted by the reader ends where it was going, so what they
// orbit is what they picked, rather than a point partway there.
const land = (cam: PerspectiveCamera) => {
  if (!flight.active) return;

  flight.elapsed = FLIGHT_SECONDS;
  advance(cam, 0);
};

const focused = computed(() =>
  props.focusKey ? byKey.value.get(props.focusKey) : undefined,
);

let dirty = true;

watch(
  () => props.scene,
  (scene) => {
    build(scene);
    dirty = true;
  },
  { immediate: true },
);

watch(
  () => props.focusKey,
  (key) => {
    if (key !== flownTo) flyTo(focused.value);
  },
  { immediate: true },
);

const ease = (t: number) =>
  t < 0.5 ? 4 * t * t * t : 1 - (-2 * t + 2) ** 3 / 2;

const advance = (cam: PerspectiveCamera, delta: number) => {
  flight.elapsed += delta;
  const t = Math.min(flight.elapsed / FLIGHT_SECONDS, 1);
  const e = ease(t);

  origin.lerpVectors(flight.fromOrigin, flight.toOrigin, e);

  // Distance in log space: a flight from across a system to a planet's
  // surface spends its time evenly over every scale on the way.
  const distance = Math.exp(
    Math.log(flight.fromDistance) * (1 - e) + Math.log(flight.toDistance) * e,
  );
  const direction = flight.fromDirection
    .clone()
    .lerp(flight.toDirection, e)
    .normalize();

  cam.position.copy(direction.multiplyScalar(distance));
  orbiting()?.target?.set(0, 0, 0);
  orbiting()?.update?.();

  if (t >= 1) flight.active = false;
};

// The first flight waits for a camera, and the limits for the controls: both
// are mounted beside the scene and can come after it.
const settle = () => {
  if (flownTo === undefined) flyTo(focused.value);
  if (!flight.active && !limited) {
    limited = limit(flownTo ? byKey.value.get(flownTo) : undefined);
  }
};

// Zoomed well out of what it is on, the map steps back out to what that
// belongs to, so zooming out is a way back as much as Escape is.
const stepOut = (cam: PerspectiveCamera) => {
  const entry = focused.value;
  if (!entry || props.scene.kind !== "system") return;

  const anchor = anchorOf(entry);
  if (!anchor) return;

  const reach = entry.radius
    ? entry.radius * 25
    : (anchor.radius ?? 1) * PLACES_NEAR * 1.2;

  if (cam.position.length() > reach) {
    flyTo(anchor, { keepDistance: true });
    emit("focus", anchor);
  }
};

// --- Near and far ---

const cameraWorld = new Vector3();
const scratch = new Vector3();

// From 1 within `near` down to 0 at twice it.
const nearness = (distance: number, near: number) =>
  Math.min(Math.max((near * 2 - distance) / near, 0), 1);

const chain = computed(() => {
  const keys = new Set<string>();
  let current = focused.value;
  while (current) {
    keys.add(current.key);
    current = anchorOf(current);
  }
  return keys;
});

const fadeOf = (entry: StarmapItem) => {
  if (chain.value.has(entry.key)) return 1;
  if (entry.role !== "place" && entry.role !== "moon") return 1;

  const anchor = anchorOf(entry);
  if (!anchor?.radius || anchor.role === "star") return 1;

  const distance = cameraWorld.distanceTo(scratch.set(...anchor.position));
  const near =
    anchor.radius * (entry.role === "moon" ? MOONS_NEAR : PLACES_NEAR);

  return nearness(distance, near);
};

// How far shown what stands on a body is.
const shownOn = (body: StarmapItem) => {
  if (!body.radius) return 0;
  const distance = cameraWorld.distanceTo(scratch.set(...body.position));
  return nearness(distance, body.radius * PLACES_NEAR);
};

// The body whose surface the camera is over: what is on its far side is
// neither labelled nor picked.
const occluder = computed(() => {
  const entry = focused.value;
  if (!entry) return undefined;
  if (entry.radius && entry.role !== "star") return entry;

  const anchor = anchorOf(entry);
  return anchor?.radius && anchor.role !== "star" ? anchor : undefined;
});

const toPoint = new Vector3();
const closest = new Vector3();
const fromCentre = new Vector3();

const occluded = (point: Vector3) => {
  const body = occluder.value;
  if (!body?.radius) return false;

  fromCentre.copy(cameraWorld).sub(scratchCentre.set(...body.position));
  toPoint.copy(point).sub(cameraWorld);
  const t = -fromCentre.dot(toPoint) / toPoint.lengthSq();
  if (t <= 0 || t >= 1) return false;

  closest.copy(fromCentre).addScaledVector(toPoint, t);
  return closest.length() < body.radius * 0.995;
};

const scratchCentre = new Vector3();

// --- Per frame ---

const resolution = new Vector2();
const projected = new Vector3();
const point = new Vector3();

const motionQuery =
  typeof window !== "undefined"
    ? window.matchMedia?.("(prefers-reduced-motion: reduce)")
    : undefined;

onBeforeRender(({ delta, elapsed }) => {
  const cam = camera.value;
  if (!(cam instanceof PerspectiveCamera)) return;

  settle();
  if (flight.active) advance(cam, delta);
  else if (limited) stepOut(cam);

  world.position.copy(origin).negate();
  cameraWorld.copy(cam.position).add(origin);

  const distance = cam.position.length();
  cam.near = Math.max(distance * 1e-3, 1e-7);
  cam.far = 1e7;
  cam.updateProjectionMatrix();

  const element = canvas();
  const height = element?.clientHeight || 1;

  if (element) {
    resolution.set(element.clientWidth, element.clientHeight);
    for (const material of lineMaterials) material.resolution.copy(resolution);
  }

  const motion = !motionQuery?.matches;
  if (motion) {
    for (const star of suns) star.animate(elapsed);
  }

  const perPixel = (2 * Math.tan((cam.fov * Math.PI) / 360)) / height;

  for (const entry of items.value) {
    const mesh = meshes.get(entry.key);
    if (!mesh) continue;

    const fade = fadeOf(entry);
    fades.set(entry.key, fade);
    mesh.visible = fade > 0.02;
    if (!mesh.visible) continue;

    if (mesh instanceof Mesh) {
      const material = mesh.material as MeshBasicMaterial;
      material.opacity = (entry.role === "place" ? 0.9 : 1) * fade;
    }

    const minimum =
      (MIN_PIXELS[entry.role] / 2) *
      perPixel *
      cameraWorld.distanceTo(point.set(...entry.position));
    const lifted =
      entry.key === hoverKey.value || entry.key === props.focusKey ? 1.3 : 1;

    mesh.scale.setScalar(Math.max(entry.radius ?? 0, minimum) * lifted);

    // A painted body turns, from where it last stood, while nothing is shown
    // on it: its places stand on the ground, and the ground would carry them
    // off. The game's own surface never turns, so a place stays over the
    // ground the game puts it on.
    if (entry.surface && !entry.texture && motion && shownOn(entry) < 0.02) {
      mesh.rotation.y += (delta / TURN_SECONDS) * Math.PI * 2;
    }
  }

  for (const orbit of orbitLines) {
    const fade = fades.get(orbit.body) ?? 1;
    lineColor(orbit.base * fade, orbit.material.color);
  }

  if (pointer.moved) {
    pointer.moved = false;
    const entry = pick(pointer.x, pointer.y);
    hoverKey.value = entry?.key ?? null;
    if (element) element.style.cursor = entry ? "pointer" : "";
  }

  if (element) declutter(cam, element);
});

// --- Picking ---

const canvas = (): HTMLCanvasElement | null => {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const instance = renderer as any;
  return instance?.domElement ?? instance?.value?.domElement ?? null;
};

const hoverKey = shallowRef<string | null>(null);

const pick = (clientX: number, clientY: number): StarmapItem | null => {
  const element = canvas();
  const cam = camera.value;
  if (!element || !cam) return null;

  const rect = element.getBoundingClientRect();
  let best: StarmapItem | null = null;
  let bestDistance = Infinity;

  for (const entry of items.value) {
    if ((fades.get(entry.key) ?? 1) < 0.5) continue;

    point.set(...entry.position);
    if (occluded(point)) continue;

    projected.copy(point).sub(origin).project(cam);
    if (projected.z > 1) continue;

    const x = ((projected.x + 1) / 2) * rect.width + rect.left;
    const y = ((1 - projected.y) / 2) * rect.height + rect.top;
    const distance = Math.hypot(x - clientX, y - clientY);

    if (distance >= PICK_PIXELS) continue;

    // Dots a few pixels apart are one spot to the pointer: the place that
    // matters more wins, as its label does.
    const closer = distance < bestDistance - TIE_PIXELS;
    const tied = Math.abs(distance - bestDistance) <= TIE_PIXELS;

    if (!best || closer || (tied && entry.rank < best.rank)) {
      best = entry;
      bestDistance = distance;
    }
  }

  return best;
};

const pointer = { x: 0, y: 0, moved: false, downX: 0, downY: 0 };

const landNow = () => {
  const cam = camera.value;
  if (cam instanceof PerspectiveCamera) land(cam);
};

const onPointerDown = (event: PointerEvent) => {
  pointer.downX = event.clientX;
  pointer.downY = event.clientY;
  landNow();
};

const onPointerMove = (event: PointerEvent) => {
  pointer.x = event.clientX;
  pointer.y = event.clientY;
  pointer.moved = true;
};

const onPointerLeave = () => {
  hoverKey.value = null;
};

// A drag turns the view; only a click picks.
const onPointerUp = (event: PointerEvent) => {
  if (
    Math.hypot(event.clientX - pointer.downX, event.clientY - pointer.downY) > 4
  ) {
    return;
  }

  const entry = pick(event.clientX, event.clientY);
  if (!entry) return;

  // A system already picked opens on a second click.
  if (entry.role === "system" && entry.key === props.focusKey) {
    emit("enter", entry);
    return;
  }

  flyTo(entry);
  emit("focus", entry);
};

const onWheel = () => {
  landNow();
};

let bound: HTMLCanvasElement | null = null;

const listeners = {
  pointerdown: onPointerDown,
  pointermove: onPointerMove,
  pointerleave: onPointerLeave,
  pointerup: onPointerUp,
  wheel: onWheel,
} as unknown as Record<string, EventListener>;

const bind = () => {
  const element = canvas();
  if (!element || element === bound) return;

  for (const [name, listener] of Object.entries(listeners)) {
    element.addEventListener(name, listener, { passive: true });
  }
  bound = element;
};

const unbind = () => {
  if (!bound) return;

  for (const [name, listener] of Object.entries(listeners)) {
    bound.removeEventListener(name, listener);
  }
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
  disposeBodies();
  sphere.dispose();
  dot.dispose();
});

// --- Labels ---

const LABEL_HEIGHT = 14;
const LABEL_CHAR_WIDTH = 6.5;

const shown = shallowRef<Set<string>>(new Set());
let lastSignature = "";

const declutter = (cam: PerspectiveCamera, element: HTMLCanvasElement) => {
  const width = element.clientWidth;
  const height = element.clientHeight;

  // Only laid out again when the view moved, the canvas was resized or what
  // is focused or hovered changed: not on every frame of an idle map.
  const signature = [
    ...cam.position.toArray().map((value) => value.toPrecision(6)),
    ...origin.toArray().map((value) => value.toPrecision(9)),
    width,
    height,
    props.focusKey,
    hoverKey.value,
  ].join("|");
  if (!dirty && signature === lastSignature) return;
  lastSignature = signature;
  dirty = false;

  const important = (entry: StarmapItem) =>
    entry.key === props.focusKey || entry.key === hoverKey.value;

  // Down over a body's surface its own name would sit in the middle of the
  // view, on top of the place the reader flew to.
  const over = occluder.value;
  const underfoot =
    over?.radius && over.key !== props.focusKey
      ? cameraWorld.distanceTo(point.set(...over.position)) < over.radius * 3
      : false;

  const candidates = items.value
    .filter(
      (entry) =>
        (entry.labelled || important(entry)) &&
        (fades.get(entry.key) ?? 1) >= 0.5 &&
        !(underfoot && entry.key === over?.key && !important(entry)),
    )
    .sort((a, b) => {
      if (important(a) !== important(b)) return important(a) ? -1 : 1;
      return a.rank - b.rank;
    });

  const placed: { x: number; y: number; half: number }[] = [];
  const next = new Set<string>();

  for (const entry of candidates) {
    point.set(...entry.position);
    if (occluded(point) && !important(entry)) continue;

    projected.copy(point).sub(origin).project(cam);
    if (projected.z > 1) continue;

    const x = ((projected.x + 1) / 2) * width;
    const y = ((1 - projected.y) / 2) * height;
    if (x < -50 || x > width + 50 || y < -20 || y > height + 20) continue;

    const half = (entry.name.length * LABEL_CHAR_WIDTH) / 2;

    const overlaps = placed.some(
      (other) =>
        Math.abs(other.x - x) < other.half + half &&
        Math.abs(other.y - y) < LABEL_HEIGHT,
    );

    if (!overlaps || important(entry)) {
      placed.push({ x, y, half });
      next.add(entry.key);
    }
  }

  const changed =
    next.size !== shown.value.size ||
    [...next].some((key) => !shown.value.has(key));

  if (changed) shown.value = next;
};

const labelled = computed(() =>
  items.value.filter((entry) => shown.value.has(entry.key)),
);

defineExpose({ reframe: () => flyTo(focused.value) });
</script>

<template>
  <primitive :object="world">
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
        :selected="entry.key === focusKey || entry.key === hoverKey"
      />
    </Html>
  </primitive>
</template>
