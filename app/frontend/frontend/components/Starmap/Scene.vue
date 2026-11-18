<script lang="ts">
export default {
  name: "StarmapScene",
};
</script>

<script lang="ts" setup>
import {
  AdditiveBlending,
  AmbientLight,
  BufferGeometry,
  CanvasTexture,
  Float32BufferAttribute,
  Points,
  PointsMaterial,
  Color,
  Group,
  Mesh,
  MeshBasicMaterial,
  MeshLambertMaterial,
  PerspectiveCamera,
  PointLight,
  RepeatWrapping,
  SphereGeometry,
  Sprite,
  SpriteMaterial,
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
import { disposeMarkers, markerOf, markerTexture } from "./icons";
import type { StarmapItem, StarmapRole, StarmapScene } from "./layout";

type Props = {
  scene: StarmapScene;
  // What the camera is on: it orbits this and every flight ends at it.
  focusKey: string | null;
  // Whether places are named where there is room, and orbits drawn. What is
  // focused or under the pointer is named either way.
  showLabels?: boolean;
  showOrbits?: boolean;
  // The system the reader just stepped out of, which the systems view pulls
  // back from.
  cameFrom?: string | null;
  // The next system is loading: what is shown fades, so the old system's
  // bodies are not seen under the new system's name.
  waiting?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  showLabels: true,
  showOrbits: true,
  cameFrom: null,
  waiting: false,
});

const emit = defineEmits<{
  // The reader picked something, or zoomed far enough out of what they were
  // on that the map stepped back out to what it belongs to.
  focus: [item: StarmapItem, zoomed?: boolean];
  // A system on the ring was opened.
  enter: [item: StarmapItem];
  // How much of the scene is shown while it fades between the systems and a
  // system, for what is drawn outside it: the system's sky.
  curtain: [shown: number];
  // A click on empty space let go of what was picked.
  release: [];
  // What is under the pointer and where it is on the canvas, in CSS pixels,
  // for the tooltip over it; null once nothing is.
  hover: [hovered: { item: StarmapItem; x: number; y: number } | null];
}>();

const { camera, controls, renderer } = useTres();
const { onBeforeRender } = useLoop();

// The smallest a thing is drawn, in pixels across: at true scale a planet seen
// from across its system is a fraction of a pixel.
const MIN_PIXELS: Record<StarmapRole, number> = {
  system: 34,
  // Above the largest planet's minimum: no gas giant is drawn past its sun.
  star: 72,
  planet: 24,
  moon: 15,
  place: 5,
};

// A planet or moon is drawn no smaller than its size on a compressed scale,
// so from afar Pyro V still reads as a giant and Euterpe as a speck: a
// radius of 1,000 km is 28 pixels across, and a gas giant's 60.
const BODY_PIXELS_AT_1000_KM = 28;
const BODY_PIXELS_CURVE = 0.35;
const BODY_PIXELS_RANGE = [14, 60] as const;

const minPixelsOf = (entry: StarmapItem) => {
  if ((entry.role !== "planet" && entry.role !== "moon") || !entry.radius) {
    return MIN_PIXELS[entry.role];
  }

  // Scene units are thousands of kilometres.
  const pixels = BODY_PIXELS_AT_1000_KM * entry.radius ** BODY_PIXELS_CURVE;
  return Math.min(Math.max(pixels, BODY_PIXELS_RANGE[0]), BODY_PIXELS_RANGE[1]);
};

// How near the pointer has to come to a thing to pick it, in pixels, and how
// close two have to be to count as one spot.
const PICK_PIXELS = 14;
const TIE_PIXELS = 3;

// An orbit narrower than this on screen, in pixels, is gone, and it takes
// this many more to fade fully in.
const ORBIT_GONE_PIXELS = 14;
const ORBIT_FADE_PIXELS = 20;

// How far each thing has grown towards its hovered size, and how quickly.
const lifts = new Map<string, number>();
const LIFT_EASE = 14;

// How much smaller a minor place's marker is than its kind's.
const MINOR_MARKER = 0.65;

// How long a flight takes, in seconds.
const FLIGHT_SECONDS = 1.8;

// One turn of a body's surface, as on the location pages.
const TURN_SECONDS = 90;

// Within this many of a body's radii the camera counts as close to it: a
// body it zooms toward becomes the focus, and a painted one stops turning.
const PLACES_NEAR = 14;

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

// A ring in the app's accent around what is focused: the one place on the
// map where colour means "this one". A line two pixels wide whatever the
// zoom, turned to the camera each frame and kept just outside the edge the
// focused thing is drawn with.
const selectionMaterial = new LineMaterial({
  color: 0x428bca,
  linewidth: 2,
});
selectionMaterial.depthTest = false;

const selection = (() => {
  const points: number[] = [];
  for (let step = 0; step <= 96; step += 1) {
    const angle = (step / 96) * Math.PI * 2;
    points.push(Math.cos(angle), Math.sin(angle), 0);
  }
  const geometry = new LineGeometry();
  geometry.setPositions(points);
  const ring = new Line2(geometry, selectionMaterial);
  ring.renderOrder = 3;
  ring.visible = false;
  return ring;
})();
world.add(selection);

// The stars behind everything, carried with the camera so the sky never comes
// closer. Built the way a night sky looks: most stars at the edge of seeing,
// a few bright ones, in the colours of their temperatures, and a band of
// faint ones where the galaxy's disc runs across the sky. Seeded, so it is
// the same sky on every visit.
const STAR_COLORS: [number, number, number, number][] = [
  // r, g, b, how common
  [0.61, 0.69, 1.0, 0.1],
  [0.79, 0.84, 1.0, 0.2],
  [1.0, 1.0, 1.0, 0.25],
  [1.0, 0.96, 0.92, 0.2],
  [1.0, 0.86, 0.69, 0.15],
  [1.0, 0.76, 0.52, 0.1],
];

const starDisc = (() => {
  const canvas = document.createElement("canvas");
  canvas.width = 32;
  canvas.height = 32;
  const context = canvas.getContext("2d");
  if (context) {
    const gradient = context.createRadialGradient(16, 16, 0, 16, 16, 16);
    gradient.addColorStop(0, "rgba(255, 255, 255, 1)");
    gradient.addColorStop(0.35, "rgba(255, 255, 255, 0.8)");
    gradient.addColorStop(1, "rgba(255, 255, 255, 0)");
    context.fillStyle = gradient;
    context.fillRect(0, 0, 32, 32);
  }
  return new CanvasTexture(canvas);
})();

const PIXEL_RATIO =
  typeof window === "undefined" ? 1 : Math.min(window.devicePixelRatio || 1, 2);

const starField = (() => {
  let seed = 1337;
  const next = () => {
    seed = (seed * 16807) % 2147483647;
    return seed / 2147483647;
  };

  const tint = () => {
    let pick = next();
    for (const [r, g, b, share] of STAR_COLORS) {
      if (pick < share) return [r, g, b];
      pick -= share;
    }
    return [1, 1, 1];
  };

  // The galaxy's disc as a great circle tilted across the sky.
  const pole = new Vector3(0.35, 0.86, 0.37).normalize();
  const across = new Vector3(1, 0, 0).cross(pole).normalize();
  const along = new Vector3().crossVectors(pole, across);

  const direction = (band: boolean) => {
    if (!band) {
      const z = next() * 2 - 1;
      const angle = next() * Math.PI * 2;
      const ring = Math.sqrt(1 - z * z);
      return new Vector3(ring * Math.cos(angle), z, ring * Math.sin(angle));
    }

    // Close to the disc, thinning away from it.
    const angle = next() * Math.PI * 2;
    const height = (next() + next() + next() - 1.5) * 0.18;
    return across
      .clone()
      .multiplyScalar(Math.cos(angle))
      .addScaledVector(along, Math.sin(angle))
      .addScaledVector(pole, height)
      .normalize();
  };

  const layer = (
    count: number,
    size: number,
    brightness: [number, number],
    bandShare: number,
  ) => {
    const positions: number[] = [];
    const colors: number[] = [];

    for (let index = 0; index < count; index += 1) {
      positions.push(...direction(next() < bandShare).toArray());
      const light =
        brightness[0] + next() ** 2 * (brightness[1] - brightness[0]);
      const [r, g, b] = tint();
      colors.push(r * light, g * light, b * light);
    }

    const geometry = new BufferGeometry();
    geometry.setAttribute("position", new Float32BufferAttribute(positions, 3));
    geometry.setAttribute("color", new Float32BufferAttribute(colors, 3));

    const points = new Points(
      geometry,
      new PointsMaterial({
        // Device pixels: the same size on a dense screen as on any other.
        size: size * PIXEL_RATIO,
        map: starDisc,
        sizeAttenuation: false,
        vertexColors: true,
        transparent: true,
        depthTest: false,
        depthWrite: false,
        blending: AdditiveBlending,
      }),
    );
    // Behind the sky, which is drawn over the stars as the game draws it:
    // fully over Nyx's, at 0.6 over Pyro's gas.
    points.renderOrder = -1001;
    points.frustumCulled = false;
    return points;
  };

  const sky = new Group();
  sky.add(
    // The faint dust of the galaxy's band, then ordinary stars, then the few
    // bright ones.
    layer(12000, 1.8, [0.08, 0.32], 0.85),
    layer(3000, 2.4, [0.25, 0.75], 0.35),
    layer(260, 3.8, [0.75, 1], 0.2),
  );
  return sky;
})();

// How far outside the drawn edge the ring sits, in pixels.
const SELECTION_GAP_PIXELS = 5;

const origin = new Vector3();

// A body is seen close up; a place is a dot a few pixels across and needs a
// fraction of the triangles, which a system of eight hundred of them adds up.
const sphere = new SphereGeometry(1, 64, 32);
const dot = new SphereGeometry(1, 12, 8);
const meshes = new Map<string, Object3D>();
const fades = new Map<string, number>();
const lineMaterials: LineMaterial[] = [];
const orbitLines: {
  body: string;
  center: Vector3;
  radius: number;
  line: Line2;
  material: LineMaterial;
  base: number;
}[] = [];
// How much of each moon's orbit can be seen, by the moon's key: the moon is
// shown with its orbit, and goes when the orbit shrinks to a few pixels.
const orbitFades = new Map<string, number>();
const textures: Texture[] = [];
const suns: StarmapSun[] = [];
const linkLines: { material: LineMaterial; base: number }[] = [];

// The labels' own elements, by key: their drop is set on them directly, since
// it changes on every frame of a zoom and Vue would redraw every label for it.
const labelElements = new Map<string, HTMLElement>();

// Orbits and tunnels in the app's neutral, as the connectors on the location
// pages: colour on the map is kept for what something is.
const LINE_COLOR = new Color(0xc8d0d8);
// The stage's backdrop, near enough: a line is mixed against it rather than
// blended, since a translucent line draws its joints twice and they show as
// a string of brighter dots.
const BACKDROP = new Color(0x0a1626);

const FOLLOWED_COLOR = new Color(0x428bca);

const lineColor = (amount: number, target = new Color(), tone = LINE_COLOR) =>
  target.lerpColors(BACKDROP, tone, amount);

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
  // A line on the map is a guide, not a body: it writes no depth, so a star
  // drawn after it covers it where the two meet.
  material.depthWrite = false;
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

// The 5.0 surfaces have their clouds painted in, and some at a far lower
// resolution than the ground -- Bloom's show as blocks. Softened by a pixel as
// they load, the blocks read as cloud and the ground barely changes.
const SURFACE_SOFTEN_PIXELS = 1.2;

const smoothed = (image: HTMLImageElement) => {
  const canvas = document.createElement("canvas");
  canvas.width = image.width;
  canvas.height = image.height;
  const context = canvas.getContext("2d");

  if (context) {
    context.filter = `blur(${SURFACE_SOFTEN_PIXELS}px)`;
    context.drawImage(image, 0, 0);
  }

  return new CanvasTexture(canvas);
};

const gameSurface = (url: string) => {
  let pending = gameSurfaces.get(url);

  if (!pending) {
    pending = loader.loadAsync(url).then((loaded) => {
      const texture = smoothed(loaded.image as HTMLImageElement);
      loaded.dispose();
      texture.colorSpace = SRGBColorSpace;
      texture.anisotropy = 4;
      return texture;
    });
    gameSurfaces.set(url, pending);
  }

  return pending;
};

// The game's own surface replaces the painted one once it has loaded; until
// then, or if it fails, the painted one stays. One that arrives after the
// scene it was for was torn down is thrown away.
const wrapInGameSurface = (
  material: MeshLambertMaterial,
  url: string,
  { terrain = false }: { terrain?: boolean } = {},
) => {
  const built = generation;

  gameSurface(url)
    .then((texture) => {
      if (built !== generation) {
        texture.dispose();
        return;
      }

      if (terrain) terrainMap(texture);

      if (!textures.includes(texture)) textures.push(texture);

      const painted = material.map;
      material.map = texture;
      material.needsUpdate = true;

      if (painted && painted !== texture) {
        painted.dispose();
        const index = textures.indexOf(painted);
        if (index !== -1) textures.splice(index, 1);
      }
    })
    .catch(() => undefined);
};

// The terrain maps are a quarter turn round from the game's surface: the
// surface at u matches them at u + 0.25.
const TERRAIN_U_OFFSET = 0.25;

const terrainMap = (texture: Texture) => {
  texture.wrapS = RepeatWrapping;
  texture.offset.x = TERRAIN_U_OFFSET;
  return texture;
};

// The elevation as relief under the light: the body's ranges and basins
// catch it where the surface alone is flat colour.
// The elevation is 16-bit, but a browser reads it at 8: smooth slopes come
// out as steps, and a bump map turns every step into a hard-edged patch. So
// it is softened once on load, and the relief kept gentle -- enough to catch
// the light on ranges and basins, not to draw the steps.
const RELIEF = 1.2;
const RELIEF_SOFTEN_PIXELS = 3;

const softened = (image: HTMLImageElement) => {
  const canvas = document.createElement("canvas");
  canvas.width = Math.min(image.width, 1024);
  canvas.height = canvas.width / 2;
  const context = canvas.getContext("2d");

  if (context) {
    context.filter = `blur(${RELIEF_SOFTEN_PIXELS}px)`;
    context.drawImage(image, 0, 0, canvas.width, canvas.height);
  }

  return new CanvasTexture(canvas);
};

const raiseRelief = (material: MeshLambertMaterial, url: string) => {
  const built = generation;
  const image = new Image();
  image.crossOrigin = "anonymous";

  image.onload = () => {
    if (built !== generation) return;

    const texture = terrainMap(softened(image));
    textures.push(texture);
    material.bumpMap = texture;
    material.bumpScale = RELIEF;
    material.needsUpdate = true;
  };
  image.src = url;
};

// How opaque the thickest cloud is: thin enough to see the ground through.
const CLOUD_COVER = 0.75;
const CLOUD_SOFTEN_PIXELS = 2;
// The share of a map read as its thickest cloud. The maps cover very
// different ranges -- Hurston's reaches 80%, Bloom's barely 35% -- so each is
// drawn against its own, and a thinly clouded body still shows its clouds.
const CLOUD_PEAK_SHARE = 0.01;

const peakOf = (data: Uint8ClampedArray) => {
  const counts = new Array<number>(256).fill(0);
  for (let index = 0; index < data.length; index += 4) counts[data[index]]++;

  let above = 0;
  const wanted = (data.length / 4) * CLOUD_PEAK_SHARE;
  for (let value = 255; value > 0; value--) {
    above += counts[value];
    if (above >= wanted) return value;
  }
  return 255;
};

// The cloud map is the cloud shader's data, its cover in the red channel;
// turned here into white cloud with that cover as its opacity.
const cloudsFrom = (image: HTMLImageElement) => {
  const canvas = document.createElement("canvas");
  canvas.width = 1024;
  canvas.height = 512;
  const context = canvas.getContext("2d", { willReadFrequently: true });

  if (context) {
    // Softened first, so cloud edges are soft rather than the map's texels.
    context.filter = `blur(${CLOUD_SOFTEN_PIXELS}px)`;
    context.drawImage(image, 0, 0, canvas.width, canvas.height);
    context.filter = "none";
    const pixels = context.getImageData(0, 0, canvas.width, canvas.height);
    const data = pixels.data;

    const peak = Math.max(peakOf(data), 1);

    for (let index = 0; index < data.length; index += 4) {
      const cover = Math.min(data[index] / peak, 1);
      data[index + 3] = cover ** 1.4 * 255 * CLOUD_COVER;
      data[index] = 255;
      data[index + 1] = 255;
      data[index + 2] = 255;
    }

    context.putImageData(pixels, 0, 0);
  }

  const texture = new CanvasTexture(canvas);
  texture.colorSpace = SRGBColorSpace;
  return terrainMap(texture);
};

const wrapInClouds = (material: MeshLambertMaterial, url: string) => {
  const built = generation;
  const image = new Image();
  image.crossOrigin = "anonymous";

  image.onload = () => {
    if (built !== generation) return;

    const texture = cloudsFrom(image);
    textures.push(texture);
    material.map = texture;
    material.needsUpdate = true;
  };
  image.src = url;
};

// A body's cloud layer, by the body's key. The game's surfaces have their
// clouds painted in -- Bloom's in coarse blocks -- so the layer drifts to and
// fro over them rather than round the body, which would uncover them.
const cloudShells = new Map<string, Mesh>();
const CLOUD_SWAY = 0.12;
const CLOUD_SWAY_SECONDS = 40;
let cloudTime = 0;

const disposeBodies = () => {
  generation += 1;
  cloudShells.clear();
  gameSurfaces.clear();
  bodies.traverse((object) => {
    // A marker's texture is shared across scenes; only its material is its own.
    if (object instanceof Sprite) object.material.dispose();
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
  linkLines.length = 0;
  orbitFades.clear();
  textures.length = 0;
  suns.length = 0;
};

const build = (scene: StarmapScene) => {
  disposeBodies();

  for (const orbit of scene.orbits) {
    const center = byKey.value.get(orbit.center);
    if (!center) continue;

    const base = byKey.value.get(orbit.body)?.role === "moon" ? 0.2 : 0.26;
    const { object, material } = line(circle(orbit.radius), { amount: base });
    // Drawn around its centre, so a moon's orbit stays exact next to its
    // planet rather than inheriting the planet's distance from the star.
    object.position.set(...center.position);
    orbitLines.push({
      body: orbit.body,
      center: new Vector3(...center.position),
      radius: orbit.radius,
      line: object,
      material,
      base,
    });
    bodies.add(object);
  }

  for (const link of scene.links) {
    const base = link.temporary ? 0.24 : 0.32;
    const { object, material } = line([...link.from, ...link.to], {
      amount: base,
      dashed: link.temporary,
    });
    linkLines.push({ material, base });
    bodies.add(object);
  }

  if (scene.kind === "system") {
    bodies.add(new PointLight(0xffffff, 1.6, 0, 0));
  }
  // Enough that the night side still shows its surface: this is a map, and a
  // body half lost in the dark is half unreadable.
  bodies.add(new AmbientLight(0xffffff, 1.3));

  for (const entry of scene.items) {
    // A system on the ring is drawn as its star.
    if (entry.role === "star" || entry.role === "system") {
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
      // The surface the game's starmap wraps the body in. The 5.0 ground
      // colour is only the soil, without the rock and water it blends with,
      // and reads as a different planet; it is the texture until the map can
      // compose the ground the way the game does.
      if (entry.texture) {
        wrapInGameSurface(lambert, entry.texture);
      } else if (entry.ground) {
        wrapInGameSurface(lambert, entry.ground, { terrain: true });
      }
      if (entry.elevation) raiseRelief(lambert, entry.elevation);
    } else if (entry.role === "place") {
      // A place is its kind's glyph, the same size on screen at any distance.
      // Not depth tested: the body it stands on would cut it in half, so what
      // is behind a body is hidden by the occlusion test instead.
      const marker = new Sprite(
        new SpriteMaterial({
          map: markerTexture(entry.kind),
          transparent: true,
          depthTest: false,
          depthWrite: false,
        }),
      );
      marker.renderOrder = 2;
      marker.position.set(...entry.position);
      bodies.add(marker);
      meshes.set(entry.key, marker);
      continue;
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

    if (entry.clouds) {
      const shell = new Mesh(
        sphere,
        new MeshLambertMaterial({
          transparent: true,
          opacity: 0,
          depthWrite: false,
        }),
      );
      shell.position.copy(mesh.position);
      shell.renderOrder = 1;
      cloudShells.set(entry.key, shell);
      bodies.add(shell);
      wrapInClouds(shell.material, entry.clouds);
    }
  }
};

// --- Flying ---

const UP = new Vector3(0, 1, 0);

const vector = (entry: StarmapItem) => new Vector3(...entry.position);

const anchorOf = (entry: StarmapItem) =>
  entry.anchor ? byKey.value.get(entry.anchor) : undefined;

// The body under a place, through the districts it is in; not the star.
const bodyFor = (entry: StarmapItem) => {
  let current = anchorOf(entry);
  while (current && !(current.radius && current.role !== "star")) {
    current = anchorOf(current);
  }
  return current;
};

// How many districts a place sits in: a sector's cluster is one deep.
const districtDepth = (entry: StarmapItem) => {
  let depth = 0;
  let current = anchorOf(entry);
  while (current?.kind === "district") {
    depth += 1;
    current = anchorOf(current);
  }
  return depth;
};

// How far above a place the camera sits, in its body's radii, by how many
// districts deep it is: a sector from high up, a cluster closer, a site in
// it closer still.
const PLACE_VIEWS = [0.5, 0.18, 0.06];

const OVERVIEW_DIRECTION = new Vector3(0, 0.55, 1).normalize();
// The ring the overview fits: the outermost planet's orbit and a little more,
// for the stations and jump points out past it.
const OVERVIEW_REACH = 1.12;
// How much of the view, edge to centre, the ring may fill.
const OVERVIEW_FILL = 0.92;

// How far back the camera has to stand for a ring around the star to fit the
// view. Seen at an angle the near side of the ring is much closer than the
// star, so a fixed distance either crops it in a small window or leaves a
// large one empty; this tries distances until every point of it fits.
const fittingDistance = (radius: number) => {
  const cam = camera.value;
  if (!(cam instanceof PerspectiveCamera)) return radius * 1.35;

  const tanV = Math.tan((cam.fov * Math.PI) / 360);
  const tanH = tanV * cam.aspect;
  const forward = OVERVIEW_DIRECTION.clone().negate();
  const right = new Vector3().crossVectors(forward, UP).normalize();
  const up = new Vector3().crossVectors(right, forward);
  const ring = new Vector3();
  const offset = new Vector3();

  const fits = (distance: number) => {
    const eye = OVERVIEW_DIRECTION.clone().multiplyScalar(distance);

    for (let step = 0; step < 48; step++) {
      const angle = (step / 48) * Math.PI * 2;
      ring.set(Math.cos(angle) * radius, 0, Math.sin(angle) * radius);
      offset.subVectors(ring, eye);
      const depth = offset.dot(forward);
      if (depth <= 0) return false;
      if (Math.abs(offset.dot(right)) / (depth * tanH) > OVERVIEW_FILL) {
        return false;
      }
      if (Math.abs(offset.dot(up)) / (depth * tanV) > OVERVIEW_FILL) {
        return false;
      }
    }
    return true;
  };

  let distance = radius;
  while (!fits(distance) && distance < radius * 20) distance *= 1.04;
  return distance;
};

const overview = () => ({
  direction: OVERVIEW_DIRECTION.clone(),
  distance: fittingDistance(props.scene.extent * OVERVIEW_REACH),
});

// Where the camera sits for an item, as a direction from it and a distance.
const viewOf = (entry: StarmapItem, current: Vector3) => {
  if (entry.role === "system") {
    return { direction: current.clone(), distance: 2.5 };
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

  // A place on or over a body is seen from above it: a region from high
  // enough to take it in, a site in it from closer.
  const body = bodyFor(entry);

  if (body?.radius) {
    const outward = position.clone().sub(vector(body)).normalize();
    const depth = districtDepth(entry);

    return {
      direction: outward
        .multiplyScalar(0.8)
        .addScaledVector(current, 0.35)
        .normalize(),
      distance: body.radius * (PLACE_VIEWS[depth] ?? PLACE_VIEWS.at(-1)!),
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
  // A flight hands the distance to the reader's zoom as soon as they scroll,
  // and the direction to them as soon as they drag; the origin it always
  // carries to the end.
  ownsDistance: true,
  ownsDirection: true,
};

// The key the camera last set out for, so a focus the scene asked for itself
// is not flown to a second time once it comes back as a prop.
let flownTo: string | null | undefined;

type Orbiting = {
  target?: Vector3;
  update?: () => void;
};

const orbiting = () => controls.value as Orbiting | null;

const flyTo = (entry: StarmapItem | undefined) => {
  const cam = camera.value;
  if (!cam) return;

  const current = cam.position.clone().normalize();
  const view = entry ? viewOf(entry, current) : overview();

  flight.fromOrigin.copy(origin);
  flight.toOrigin.copy(entry ? vector(entry) : new Vector3());
  flight.fromDistance = Math.max(cam.position.length(), 1e-6);
  flight.toDistance = view.distance;
  flight.fromDirection.copy(current);
  flight.toDirection.copy(view.direction);
  flight.ownsDistance = true;
  flight.ownsDirection = true;
  flight.elapsed = 0;
  flight.active = true;

  flownTo = entry?.key ?? null;
};

const focused = computed(() =>
  props.focusKey ? byKey.value.get(props.focusKey) : undefined,
);

let dirty = true;

// --- Between the systems and a system ---
//
// The two are different scales, so the camera cannot fly from one into the
// other. Instead the star is kept and everything else fades: into a system,
// the camera dives at its star as the ring fades, and arrives far out over
// the system as it fades in; out of one, it climbs away from the star as the
// system fades, and the ring fades in as it pulls back from that system.

const CURTAIN_EASE = 6;
const curtain = { value: 1, goal: 1 };
let curtainReported = 1;
// What stays in view while the rest fades: the star the camera is on.
let curtainKeep: string | null = null;
// Between leaving one scene and arriving in the next, the focus the page
// reports is the old one's or none; the camera is not sent after it.
let crossing = false;
let leaving: (() => void) | null = null;

const shownOf = (entry: StarmapItem) =>
  entry.key === curtainKeep ? 1 : curtain.value;

const DIVE = 0.3;

// How close to its star, edge to edge on screen, a body or place is gone, and
// over how many pixels more it fades in: clear of the sun's glow.
const STAR_CLEAR_PIXELS = 4;
const STAR_CLEAR_FADE_PIXELS = 14;

const starItem = computed(() =>
  items.value.find((entry) => entry.role === "star"),
);
const PULL_BACK_FROM = 0.75;

const arrive = (scene: StarmapScene) => {
  crossing = false;
  entering = null;
  leaving?.();
  leaving = null;
  flight.active = false;
  curtain.value = 0;
  curtain.goal = 1;
  origin.set(0, 0, 0);
  originGoal.set(0, 0, 0);
  flownTo = undefined;

  if (scene.kind === "system") {
    curtainKeep =
      scene.items.find((entry) => entry.role === "star")?.key ?? null;
    // Far out over the system, with its star a point as it was at the end
    // of the dive, and zooming in from there. Set here rather than left to
    // the first frame: the new focus sends the camera off before that, and
    // it would start from the dive's distance, deep inside the system.
    zoom.distance = zoom.goal = scene.extent * ARRIVAL_DISTANCE;
    camera.value?.position.setLength(zoom.distance);
    return;
  }

  const left = scene.items.find((entry) => entry.slug === props.cameFrom);
  curtainKeep = left?.key ?? null;
  if (left) {
    origin.set(...left.position);
    originGoal.copy(origin);
    zoom.distance = zoom.goal = PULL_BACK_FROM;
    camera.value?.position.setLength(PULL_BACK_FROM);
  }
};

// Out of a system: climbs away from its star as the system fades, and
// resolves once only the star is left.
const leave = () =>
  new Promise<void>((resolve) => {
    const cam = camera.value;
    if (props.scene.kind !== "system" || !cam) {
      resolve();
      return;
    }

    crossing = true;
    entering = null;
    curtainKeep =
      props.scene.items.find((entry) => entry.role === "star")?.key ?? null;

    flight.fromOrigin.copy(origin);
    flight.toOrigin.set(0, 0, 0);
    flight.fromDistance = Math.max(cam.position.length(), 1e-6);
    flight.toDistance = props.scene.extent * ARRIVAL_DISTANCE;
    flight.fromDirection.copy(cam.position).normalize();
    flight.toDirection.copy(overview().direction);
    flight.ownsDistance = true;
    flight.ownsDirection = true;
    flight.elapsed = 0;
    flight.active = true;
    flownTo = null;

    leaving = resolve;
  });

const crossFrame = (delta: number) => {
  // The system fades once the climb is under way, not as it starts.
  if (leaving && flight.elapsed > FLIGHT_SECONDS * 0.3) curtain.goal = 0;

  curtain.value +=
    (curtain.goal - curtain.value) * Math.min(delta * CURTAIN_EASE, 1);
  if (Math.abs(curtain.goal - curtain.value) < 0.01) {
    curtain.value = curtain.goal;
  }
  if (curtain.value !== curtainReported) {
    curtainReported = curtain.value;
    emit("curtain", curtain.value);
  }

  if (curtain.value > 0.03) return;

  if (entering && !flight.active) {
    emit("enter", entering);
    entering = null;
  }

  if (leaving && !flight.active) {
    leaving();
    leaving = null;
  }
};

const starOf = (scene: StarmapScene) =>
  scene.items.find((entry) => entry.role === "star")?.key;

watch(
  () => props.scene,
  (scene, before) => {
    build(scene);
    dirty = true;
    // Another kind of scene, or another system: a refetch of the same one
    // is not an arrival.
    if (
      before &&
      (before.kind !== scene.kind || starOf(before) !== starOf(scene))
    ) {
      arrive(scene);
    }
  },
  { immediate: true },
);

watch(
  () => props.waiting,
  (waiting) => {
    if (!waiting) return;

    crossing = true;
    curtain.goal = 0;
    // From the systems view the star dived at stays; from another system
    // nothing of it does.
    if (props.scene.kind === "system") curtainKeep = null;
  },
);

watch(
  () => props.focusKey,
  (key) => {
    if (crossing) return;
    if (key !== flownTo) flyTo(focused.value);
  },
  { immediate: true },
);

const ease = (t: number) =>
  t < 0.5 ? 4 * t * t * t : 1 - (-2 * t + 2) ** 3 / 2;

const logLerp = (from: number, to: number, t: number) =>
  Math.exp(Math.log(from) * (1 - t) + Math.log(to) * t);

// From 0 before `from` to 1 after `to`, eased.
const phase = (t: number, from: number, to: number) =>
  ease(Math.min(Math.max((t - from) / (to - from), 0), 1));

// A flight rises until both ends are in view, crosses at that height, and
// comes down on the other side, the way a map flies between two places.
// Crossing and zooming at once would pass close over the empty space between
// them, which reads as heading somewhere else first.
const advance = (cam: PerspectiveCamera, delta: number) => {
  flight.elapsed += delta;
  const t = Math.min(flight.elapsed / FLIGHT_SECONDS, 1);
  const e = ease(t);

  origin.lerpVectors(flight.fromOrigin, flight.toOrigin, phase(t, 0.2, 0.8));
  originGoal.copy(origin);

  // Distance in log space: a flight from across a system to a planet's
  // surface spends its time evenly over every scale on the way.
  if (flight.ownsDistance) {
    const span = flight.fromOrigin.distanceTo(flight.toOrigin) * 1.1;
    const height = Math.max(flight.fromDistance, flight.toDistance, span);

    zoom.distance =
      t < 0.5
        ? logLerp(flight.fromDistance, height, phase(t, 0, 0.45))
        : logLerp(height, flight.toDistance, phase(t, 0.55, 1));
    zoom.goal = zoom.distance;
  }

  if (flight.ownsDirection) {
    const direction = flight.fromDirection
      .clone()
      .lerp(flight.toDirection, e)
      .normalize();
    cam.position.copy(direction);
  }

  if (t >= 1) {
    flight.active = false;

    // At the star, the camera keeps diving at it as the ring fades; the
    // system opens once only the star is left.
    if (entering) {
      crossing = true;
      curtainKeep = entering.key;
      curtain.goal = 0;
      zoom.goal = zoom.distance * DIVE;
    }
  }
};

// --- Zooming ---
//
// The map's own zoom rather than the orbit controls': smooth in log space so
// one gesture crosses scales evenly, toward what is under the pointer rather
// than always into the centre, and in step with flights instead of fighting
// them.

// How much one pixel of scroll zooms, and how quickly the view catches up.
const ZOOM_PER_PIXEL = 0.0017;
const ZOOM_EASE = 12;

const zoom = { distance: 0, goal: 0 };
// Where the origin is heading as the reader zooms toward something.
const originGoal = new Vector3();

// How close the camera may come to where it is centred: just outside the
// body it is centred on, or half a kilometre from anything else.
const nearest = () => {
  for (const entry of items.value) {
    if (!entry.radius) continue;
    const depth = originGoal.distanceTo(point.set(...entry.position));
    if (depth >= entry.radius) continue;

    // Measured from the surface, not the centre: a place on the ground,
    // a little under the radius or a little over it with the terrain, keeps
    // the camera just above the ground either way. Kept at a full radius
    // from the centre, places either side of the radius would flip the limit
    // between a thousand kilometres and half of one as a zoom passed them.
    return Math.max(entry.radius * 1.08 - depth, 0.0005);
  }
  return 0.0005;
};

// How close the camera has to come to something it is zooming toward before
// that becomes the focus: near enough that it fills a fair part of the view.
const reachOf = (entry: StarmapItem) => {
  if (entry.radius) return entry.radius * 25;

  const body = bodyFor(entry);
  return body?.radius ? body.radius * PLACES_NEAR * 1.2 : 30;
};

const clampGoal = () => {
  zoom.goal = Math.min(Math.max(zoom.goal, nearest()), props.scene.extent * 4);
};

const pointedAt = new Vector3();
const goalCamera = new Vector3();

const zoomBy = (factor: number, clientX: number, clientY: number) => {
  const cam = camera.value;
  if (!cam || zoom.distance === 0) return;

  if (flight.active && flight.ownsDistance) {
    flight.ownsDistance = false;
    zoom.goal = zoom.distance;
  }

  zoom.goal *= factor;
  clampGoal();

  if (props.scene.kind !== "system") return;

  // Out, the view stays centred where it is: zooming out is not going back.
  if (factor < 1) {
    // In: toward what is under the pointer, which becomes the focus once the
    // camera is close enough that zooming out again would not step back out.
    const entry = pick(clientX, clientY);
    if (!entry || entry.key === props.focusKey) return;

    pointedAt.set(...entry.position);
    if (!flight.active) originGoal.lerp(pointedAt, 1 - factor);

    goalCamera.copy(cam.position).setLength(zoom.goal).add(originGoal);

    // It becomes the focus without a flight: the view keeps easing toward
    // it as the zoom does. A flight sets off from a standstill, and zooming
    // through a body's places hands the focus on from one to the next, so the
    // view would stop and start at every one of them.
    if (goalCamera.distanceTo(pointedAt) < reachOf(entry) * 0.8) {
      flight.active = false;
      originGoal.copy(pointedAt);
      // Clamped against where the view now centres, or it would ease on
      // down inside the body it just reached.
      clampGoal();
      flownTo = entry.key;
      emit("focus", entry, true);
    }
  }
};

// The first flight waits for a camera: it is mounted beside the scene and can
// come after it. A system opens from far out, so arriving in one reads as
// the zoom into it that a click on the ring began.
const settle = (cam: PerspectiveCamera) => {
  if (zoom.distance === 0) {
    if (props.scene.kind === "system") {
      cam.position.setLength(props.scene.extent * ARRIVAL_DISTANCE);
    }
    zoom.distance = zoom.goal = cam.position.length() || 1;
  }
  if (flownTo === undefined) flyTo(focused.value);
};

const ARRIVAL_DISTANCE = 30;

// A system on the ring the camera is flying into, opened when it arrives.
let entering: StarmapItem | null = null;

const move = (cam: PerspectiveCamera, delta: number) => {
  settle(cam);

  if (flight.active) advance(cam, delta);

  const k = 1 - Math.exp(-delta * ZOOM_EASE);

  if (!flight.active || !flight.ownsDistance) {
    zoom.distance = logLerp(zoom.distance, zoom.goal, k);
  }
  if (!flight.active) origin.lerp(originGoal, k);

  cam.position.setLength(zoom.distance);
  orbiting()?.target?.set(0, 0, 0);
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

// What is focused, and what it belongs to, always shows; the rest goes in
// the steps the layout gives each place as the camera moves away.
const fadeOf = (entry: StarmapItem) => {
  if (chain.value.has(entry.key)) return 1;

  // What is in a district only shows once the district is zoomed onto.
  const anchor = anchorOf(entry);
  if (anchor?.kind === "district" && !chain.value.has(anchor.key)) return 0;

  if (entry.role === "moon") return orbitFades.get(entry.key) ?? 1;
  if (entry.near === null) return 1;

  const from = entry.nearFrom === "anchor" ? (anchorOf(entry) ?? entry) : entry;
  const distance = cameraWorld.distanceTo(scratch.set(...from.position));

  return nearness(distance, entry.near);
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

  return bodyFor(entry);
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

const discs: {
  key: string;
  x: number;
  y: number;
  across: number;
  away: number;
}[] = [];

const markerScreen = new Vector3();

const coveredByBody = (
  entry: StarmapItem,
  cam: PerspectiveCamera,
  away: number,
) => {
  if (entry.key === props.focusKey || entry.key === hoverKey.value) {
    return false;
  }

  markerScreen
    .set(...entry.position)
    .sub(origin)
    .project(cam);
  const element = canvas();
  const x = ((markerScreen.x + 1) / 2) * (element?.clientWidth ?? 1);
  const y = ((1 - markerScreen.y) / 2) * (element?.clientHeight ?? 1);

  return discs.some(
    (disc) =>
      disc.key !== entry.anchor &&
      disc.away < away * 1.5 &&
      Math.hypot(disc.x - x, disc.y - y) < disc.across + 6,
  );
};

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

  move(cam, delta);
  crossFrame(delta);

  world.position.copy(origin).negate();
  starField.position.copy(cam.position);
  starField.scale.setScalar(Math.max(cam.position.length() * 4, 1));
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
    cloudTime += delta;
  }

  const perPixel = (2 * Math.tan((cam.fov * Math.PI) / 360)) / height;

  // Where each body sits on screen and how wide it is drawn: a marker that
  // is not the body's own and lands on it gives way, so a planet is not
  // buried under the stations at its Lagrange points.
  discs.length = 0;
  for (const entry of items.value) {
    if (!entry.radius || entry.role === "place") continue;
    if (entry.role === "moon" && (orbitFades.get(entry.key) ?? 1) < 0.5) {
      continue;
    }

    point.set(...entry.position);
    const away = cameraWorld.distanceTo(point);
    projected.copy(point).sub(origin).project(cam);
    if (projected.z > 1) continue;

    discs.push({
      key: entry.key,
      x: ((projected.x + 1) / 2) * (element?.clientWidth ?? 1),
      y: ((1 - projected.y) / 2) * height,
      across: Math.max(
        entry.radius / (perPixel * away),
        minPixelsOf(entry) / 2,
      ),
      away,
    });
  }

  // An orbit, and the moon on it, show while the orbit is wide enough on
  // screen to read: from a moon's planet they are all there, from across the
  // system they would be a knot of rings around a dot. One that is gone is
  // hidden rather than drawn in the backdrop's colour, which the stage's
  // gradient shows up as a dark ring.
  for (const orbit of orbitLines) {
    const across =
      orbit.radius / (perPixel * cameraWorld.distanceTo(orbit.center));
    const fade = Math.min(
      Math.max((across - ORBIT_GONE_PIXELS) / ORBIT_FADE_PIXELS, 0),
      1,
    );

    orbitFades.set(orbit.body, fade);
    orbit.line.visible = props.showOrbits && fade > 0.02;
    lineColor(orbit.base * fade * curtain.value, orbit.material.color);

    // The orbit of what is focused is drawn in the accent, a little wider:
    // the one ring the reader is following.
    const followed = orbit.body === props.focusKey;
    if (followed) {
      lineColor(
        fade * curtain.value * 0.75,
        orbit.material.color,
        FOLLOWED_COLOR,
      );
    }
    orbit.material.linewidth = followed ? 2 : 1.2;
  }

  // From far out a system is its star: what orbits it closes on it on
  // screen, and is let go before it is drawn over the sun.
  const star = props.scene.kind === "system" ? starItem.value : undefined;
  const starPixel = star
    ? perPixel * cameraWorld.distanceTo(scratch.set(...star.position))
    : 0;
  // The sun and what orbits it are drawn no smaller than a few pixels, so
  // they meet on screen long before their centres do: what counts is the gap
  // between the two as drawn.
  const starDrawn = star
    ? Math.max((star.radius ?? 0) / starPixel, MIN_PIXELS.star / 2)
    : 0;
  const clearOfStar = (entry: StarmapItem) => {
    if (!star || entry.key === star.key) return 1;
    const apart =
      point.set(...entry.position).distanceTo(scratch.set(...star.position)) /
      starPixel;
    const drawn =
      entry.role === "place"
        ? (markerOf(entry.kind).size * (entry.minor ? MINOR_MARKER : 1)) / 2
        : Math.max((entry.radius ?? 0) / starPixel, minPixelsOf(entry) / 2) *
          (lifts.get(entry.key) ?? 1);
    const gap = apart - starDrawn - drawn;

    return Math.min(
      Math.max((gap - STAR_CLEAR_PIXELS) / STAR_CLEAR_FADE_PIXELS, 0),
      1,
    );
  };

  for (const entry of items.value) {
    const mesh = meshes.get(entry.key);
    if (!mesh) continue;

    const fade = fadeOf(entry) * shownOf(entry) * clearOfStar(entry);
    fades.set(entry.key, fade);
    point.set(...entry.position);

    // Grows under the pointer, over a moment rather than in one frame. Not
    // when focused: the ring marks that, and a zoom that hands the focus on
    // would shrink what it leaves.
    const lift = entry.key === hoverKey.value ? HOVER_LIFT : 1;
    const previous = lifts.get(entry.key) ?? 1;
    const lifted =
      previous + (lift - previous) * Math.min(delta * LIFT_EASE, 1);
    if (Math.abs(lifted - 1) < 0.001) lifts.delete(entry.key);
    else lifts.set(entry.key, lifted);
    const away = cameraWorld.distanceTo(point);

    if (mesh instanceof Sprite) {
      if (fade > 0.02 && coveredByBody(entry, cam, away)) {
        fades.set(entry.key, 0);
        mesh.visible = false;
        continue;
      }

      mesh.visible = fade > 0.02 && !occluded(point);
      if (!mesh.visible) continue;

      mesh.material.opacity = fade;
      mesh.scale.setScalar(
        markerOf(entry.kind).size *
          (entry.minor ? MINOR_MARKER : 1) *
          perPixel *
          away *
          lifted,
      );
      continue;
    }

    mesh.visible = fade > 0.02;
    if (!mesh.visible) continue;

    if (mesh instanceof Mesh) {
      const material = mesh.material as MeshBasicMaterial;
      material.opacity = fade;
    }

    const minimum = (minPixelsOf(entry) / 2) * perPixel * away;

    // Only the size it is drawn at beyond its own grows: a body seen at its
    // true size keeps it, or its places would float off its ground.
    mesh.scale.setScalar(Math.max(entry.radius ?? 0, minimum * lifted));
    // A star has no opacity of its own to fade; it shrinks away instead.
    if (!(mesh instanceof Mesh)) mesh.scale.multiplyScalar(fade);

    const shell = cloudShells.get(entry.key);
    if (shell) {
      shell.scale.copy(mesh.scale).multiplyScalar(1.012);
      // Thinner as the camera comes down to the surface, where the places
      // under the cloud are what the reader came for.
      (shell.material as MeshLambertMaterial).opacity =
        fade * (1 - 0.35 * shownOn(entry));
      shell.rotation.y =
        CLOUD_SWAY * Math.sin((cloudTime / CLOUD_SWAY_SECONDS) * Math.PI * 2);
    }

    // A painted body turns, from where it last stood, while nothing is shown
    // on it: its places stand on the ground, and the ground would carry them
    // off. The game's own surface never turns, so a place stays over the
    // ground the game puts it on.
    if (entry.surface && !entry.texture && motion && shownOn(entry) < 0.02) {
      mesh.rotation.y += (delta / TURN_SECONDS) * Math.PI * 2;
    }
  }

  for (const link of linkLines) {
    lineColor(link.base * curtain.value, link.material.color);
  }

  // The ring sits around the focused thing at the size it is drawn.
  const selected = props.focusKey ? meshes.get(props.focusKey) : undefined;
  const selectedItem = props.focusKey
    ? byKey.value.get(props.focusKey)
    : undefined;
  selection.visible =
    curtain.value > 0.5 &&
    !!selected?.visible &&
    !!selectedItem &&
    selectedItem.role !== "star" &&
    selectedItem.role !== "system";
  if (selection.visible && selected) {
    const drawn =
      selected instanceof Sprite ? selected.scale.x / 2 : selected.scale.x;
    const pixel = perPixel * cameraWorld.distanceTo(selected.position);

    selection.position.copy(selected.position);
    selection.quaternion.copy(cam.quaternion);
    selection.scale.setScalar(drawn + SELECTION_GAP_PIXELS * pixel);
    selectionMaterial.resolution.copy(resolution);
  }

  if (pointer.moved) {
    pointer.moved = false;
    const entry = pick(pointer.x, pointer.y);
    hoverKey.value = entry?.key ?? null;
    if (element) element.style.cursor = entry ? "pointer" : "";
  }

  // The camera has moved since the last render, and its matrices with it:
  // labels laid out against the old ones land somewhere else.
  cam.updateMatrixWorld();
  if (element) reportHover(cam, element);
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

// Two fingers on a touch screen zoom as the wheel does, about their middle.
const touches = new Map<number, { x: number; y: number }>();
let pinch = 0;

const pinchSpan = () => {
  const [a, b] = [...touches.values()];
  return a && b ? Math.hypot(a.x - b.x, a.y - b.y) : 0;
};

const onPointerDown = (event: PointerEvent) => {
  pointer.downX = event.clientX;
  pointer.downY = event.clientY;
  // A drag turns the view from here on, whatever a flight was doing to it.
  flight.ownsDirection = false;

  if (event.pointerType === "touch") {
    touches.set(event.pointerId, { x: event.clientX, y: event.clientY });
    pinch = pinchSpan();
  }
};

const onPointerMove = (event: PointerEvent) => {
  pointer.x = event.clientX;
  pointer.y = event.clientY;
  pointer.moved = true;

  if (event.pointerType === "touch" && touches.has(event.pointerId)) {
    touches.set(event.pointerId, { x: event.clientX, y: event.clientY });
    const span = pinchSpan();

    if (pinch && span) {
      const [a, b] = [...touches.values()];
      zoomBy(pinch / span, (a.x + b.x) / 2, (a.y + b.y) / 2);
    }
    pinch = span;
  }
};

const onPointerEnd = (event: PointerEvent) => {
  touches.delete(event.pointerId);
  pinch = pinchSpan();
};

const onPointerLeave = () => {
  hoverKey.value = null;
};

// Where the hovered thing sits on screen, sent on whenever it moves by a
// pixel: the tooltip follows it as the camera turns.
let reported = "";
const hovered = new Vector3();

const reportHover = (cam: PerspectiveCamera, element: HTMLCanvasElement) => {
  const entry = hoverKey.value ? byKey.value.get(hoverKey.value) : undefined;
  const mesh = entry ? meshes.get(entry.key) : undefined;

  if (!entry || !mesh?.visible) {
    if (reported) emit("hover", null);
    reported = "";
    return;
  }

  hovered.copy(mesh.position).sub(origin).project(cam);
  const x = Math.round(((hovered.x + 1) / 2) * element.clientWidth);
  const y = Math.round(((1 - hovered.y) / 2) * element.clientHeight);

  // Clear of the thing itself: above the edge it is drawn with.
  const height = element.clientHeight || 1;
  const perPixel = (2 * Math.tan((cam.fov * Math.PI) / 360)) / height;
  const drawn = mesh instanceof Sprite ? mesh.scale.x / 2 : mesh.scale.x;
  const lift = Math.round(
    drawn / (perPixel * cameraWorld.distanceTo(mesh.position)),
  );

  const signature = `${entry.key}|${x}|${y - lift}`;
  if (signature === reported) return;
  reported = signature;

  emit("hover", { item: entry, x, y: y - lift });
};

// A drag turns the view; only a click picks.
const onPointerUp = (event: PointerEvent) => {
  const pinching = touches.size > 1;
  onPointerEnd(event);
  if (pinching) return;

  if (
    Math.hypot(event.clientX - pointer.downX, event.clientY - pointer.downY) > 4
  ) {
    return;
  }

  const entry = pick(event.clientX, event.clientY);

  // A click on empty space lets go of what was picked. The camera stays where
  // it is: the focus falls back to the star without a flight to it.
  if (!entry) {
    const centre = items.value.find(
      (item) => item.role === "star" || item.role === "system",
    );
    if (props.focusKey && props.focusKey !== centre?.key) {
      flownTo = props.scene.kind === "system" ? (centre?.key ?? null) : null;
      emit("release");
    }
    return;
  }

  // A system opens on a click: there is nothing on the ring to fly to.
  // A system is flown into: the camera closes on its star and the system
  // opens as it arrives.
  if (entry.role === "system") {
    flyTo(entry);
    entering = entry;
    return;
  }

  flyTo(entry);
  emit("focus", entry);
};

const onWheel = (event: WheelEvent) => {
  event.preventDefault();

  // Lines and pages, as some mice and settings report them, in pixels.
  const unit = event.deltaMode === 1 ? 16 : event.deltaMode === 2 ? 400 : 1;
  zoomBy(
    Math.exp(event.deltaY * unit * ZOOM_PER_PIXEL),
    event.clientX,
    event.clientY,
  );
};

let bound: HTMLCanvasElement | null = null;

const listeners = {
  pointerdown: onPointerDown,
  pointermove: onPointerMove,
  pointerleave: onPointerLeave,
  pointerup: onPointerUp,
  pointercancel: onPointerEnd,
  wheel: onWheel,
} as unknown as Record<string, EventListener>;

const bind = () => {
  const element = canvas();
  if (!element || element === bound) return;

  for (const [name, listener] of Object.entries(listeners)) {
    // The wheel is not passive: it zooms the map, not the page.
    element.addEventListener(name, listener, { passive: name !== "wheel" });
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
  selection.geometry.dispose();
  selectionMaterial.dispose();
  starField.traverse((object) => {
    if (object instanceof Points) {
      object.geometry.dispose();
      (object.material as PointsMaterial).dispose();
    }
  });
  starDisc.dispose();
  unbind();
  disposeBodies();
  sphere.dispose();
  dot.dispose();
  disposeMarkers();
});

// --- Labels ---

const LABEL_HEIGHT = 14;
const LABEL_CHAR_WIDTH = 6.5;

const shown = shallowRef<Set<string>>(new Set());
let lastSignature = "";

// How much a body under the pointer grows: enough to answer the
// pointer, not so much that it crowds what is around it.
const HOVER_LIFT = 1.15;

// How far under its point a name sits by default, as Label.vue draws it.
const LABEL_DROPS: Record<StarmapRole, number> = {
  system: 24,
  star: 24,
  planet: 15,
  moon: 15,
  place: 15,
};

// From a body's drawn edge to the middle of its name: half a line and a gap.
const LABEL_BELOW_PIXELS = 11;
// A label's element, found by its key and kept while it is in the page.
// Labels are drawn into the page outside this component's own tree, so a
// template ref never reaches them.
const labelElement = (key: string) => {
  const known = labelElements.get(key);
  if (known?.isConnected) return known;

  const found = document.querySelector<HTMLElement>(
    `[data-starmap-label="${CSS.escape(key)}"]`,
  );
  if (found) labelElements.set(key, found);
  else labelElements.delete(key);
  return found ?? undefined;
};

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
    props.showLabels,
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
        ((props.showLabels && entry.labelled) || important(entry)) &&
        (fades.get(entry.key) ?? 1) >= 0.5 &&
        !(underfoot && entry.key === over?.key && !important(entry)),
    )
    .sort((a, b) => {
      if (important(a) !== important(b)) return important(a) ? -1 : 1;
      return a.rank - b.rank;
    });

  const placed: { x: number; y: number; half: number }[] = [];
  const next = new Set<string>();
  const perPixel = (2 * Math.tan((cam.fov * Math.PI) / 360)) / height;

  for (const entry of candidates) {
    point.set(...entry.position);
    if (occluded(point) && !important(entry)) continue;

    projected.copy(point).sub(origin).project(cam);
    if (projected.z > 1) continue;

    const x = ((projected.x + 1) / 2) * width;
    const y = ((1 - projected.y) / 2) * height;
    if (x < -50 || x > width + 50 || y < -20 || y > height + 20) continue;

    // A star's or a system's name is set in wide, spaced capitals.
    const wide = entry.role === "star" || entry.role === "system" ? 1.7 : 1;
    const half = (entry.name.length * LABEL_CHAR_WIDTH * wide) / 2;

    // A body's name goes under its disc as drawn, however large that is,
    // but not with the hover's growth: the name stays where it was. To a
    // tenth of a pixel: whole pixels step on every frame of a zoom while the
    // disc grows smoothly, and the name judders under it.
    const mesh = meshes.get(entry.key);
    const drop =
      mesh && !(mesh instanceof Sprite) && entry.role !== "system"
        ? Math.round(
            (mesh.scale.x /
              (lifts.get(entry.key) ?? 1) /
              (perPixel * cameraWorld.distanceTo(point)) +
              LABEL_BELOW_PIXELS) *
              10,
          ) / 10
        : undefined;
    // Where the name is drawn, which is what has to stay clear of the rest.
    const labelY = y + (drop ?? LABEL_DROPS[entry.role]);

    // Clear of the other names, and of every disc but its own: a name over
    // the sun or over another planet reads as that one's.
    const overlaps =
      placed.some(
        (other) =>
          Math.abs(other.x - x) < other.half + half &&
          Math.abs(other.y - labelY) < LABEL_HEIGHT,
      ) ||
      discs.some((disc) => {
        if (disc.key === entry.key) return false;
        const nearestX = Math.min(Math.max(disc.x, x - half), x + half);
        const nearestY = Math.min(
          Math.max(disc.y, labelY - LABEL_HEIGHT / 2),
          labelY + LABEL_HEIGHT / 2,
        );
        return Math.hypot(disc.x - nearestX, disc.y - nearestY) < disc.across;
      });

    if (!overlaps || important(entry)) {
      placed.push({ x, y: labelY, half });
      next.add(entry.key);

      // Set whenever it differs from what the element shows: a label drawn
      // anew starts at its role's default.
      const element = drop === undefined ? undefined : labelElement(entry.key);
      const transform = `translateY(${drop}px)`;
      if (element && element.style.transform !== transform) {
        element.style.transform = transform;
      }
    }
  }

  const changed =
    next.size !== shown.value.size ||
    [...next].some((key) => !shown.value.has(key));

  if (changed) {
    shown.value = next;
    // The labels that just appeared are drawn after this, and get their
    // place under their disc on the next pass.
    dirty = true;
  }
};

const labelled = computed(() =>
  items.value.filter((entry) => shown.value.has(entry.key)),
);

// A step of the zoom buttons, around wherever the view is centred.
const zoomStep = (factor: number) => {
  if (zoom.distance === 0) return;

  if (flight.active && flight.ownsDistance) {
    flight.ownsDistance = false;
    zoom.goal = zoom.distance;
  }

  zoom.goal *= factor;
  clampGoal();
};

defineExpose({ reframe: () => flyTo(focused.value), zoomStep, leave });
</script>

<template>
  <primitive :object="starField" />
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
        :data-starmap-label="entry.key"
        :selected="entry.key === focusKey || entry.key === hoverKey"
      />
    </Html>
  </primitive>
</template>
