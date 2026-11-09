import {
  AdditiveBlending,
  BackSide,
  CanvasTexture,
  CircleGeometry,
  Color,
  DoubleSide,
  Group,
  type Material,
  Mesh,
  MeshBasicMaterial,
  type Object3D,
  PlaneGeometry,
  SRGBColorSpace,
  SphereGeometry,
  type Texture,
  Vector3,
} from "three";
import { Reflector } from "three/examples/jsm/objects/Reflector.js";

// A room after the game's character customizer: a dark blue haze, tall
// pill-shaped light panels ribbed with light, and a glossy floor that mirrors
// them. Its own geometry, since the customizer's models are not in the game
// data, stood around the figure's feet.

export const BACKDROP_RADIUS = 9;

// The room is built around a standing figure. Anything larger -- a ship --
// gets the room grown around it, so it stands inside and the camera framing
// it does too.
const FIGURE_REACH = 2.5;

export const backdropScale = (size: Vector3) =>
  Math.max(1, Math.max(size.x, size.y, size.z) / FIGURE_REACH);
const PANEL_WIDTH = 0.5;
const PANEL_HEIGHT = 2.4;

const canvas = (width: number, height: number) => {
  const element = document.createElement("canvas");
  element.width = width;
  element.height = height;

  return { element, context: element.getContext("2d") };
};

const texture = (element: HTMLCanvasElement) => {
  const map = new CanvasTexture(element);
  map.colorSpace = SRGBColorSpace;

  return map;
};

// Navy at the ceiling, a haze just above the horizon, and the floor's rim
// colour below it.
const hazeTexture = () => {
  const { element, context } = canvas(4, 512);
  if (!context) return undefined;

  const haze = context.createLinearGradient(0, 0, 0, 512);
  haze.addColorStop(0, "#010307");
  haze.addColorStop(0.3, "#03101b");
  haze.addColorStop(0.46, "#061a28");
  haze.addColorStop(0.54, "#010307");
  haze.addColorStop(1, "#010307");
  context.fillStyle = haze;
  context.fillRect(0, 0, 4, 512);

  return texture(element);
};

// A pill of white light with darker vertical ribs, its edge fading to blue.
const panelTexture = () => {
  const width = 128;
  const height = 640;
  const { element, context } = canvas(width, height);
  if (!context) return undefined;

  const radius = width / 2;
  context.beginPath();
  context.roundRect(4, 4, width - 8, height - 8, radius - 4);
  context.closePath();

  const glow = context.createLinearGradient(0, 0, width, 0);
  glow.addColorStop(0, "#2c5a86");
  glow.addColorStop(0.2, "#a9cbe6");
  glow.addColorStop(0.8, "#a9cbe6");
  glow.addColorStop(1, "#2c5a86");
  context.fillStyle = glow;
  context.fill();

  context.save();
  context.clip();
  context.fillStyle = "rgba(40, 90, 140, 0.55)";
  for (let rib = 14; rib < width - 10; rib += 11) {
    context.fillRect(rib, 0, 3, height);
  }
  context.restore();

  return texture(element);
};

// The soft bloom a bright panel throws into the haze around it.
const haloTexture = () => {
  const size = 256;
  const { element, context } = canvas(size, size);
  if (!context) return undefined;

  const halo = context.createRadialGradient(
    size / 2,
    size / 2,
    0,
    size / 2,
    size / 2,
    size / 2,
  );
  halo.addColorStop(0, "rgba(110, 170, 240, 0.35)");
  halo.addColorStop(0.45, "rgba(40, 100, 170, 0.1)");
  halo.addColorStop(1, "rgba(30, 80, 140, 0)");
  context.fillStyle = halo;
  context.fillRect(0, 0, size, size);

  return texture(element);
};

// The floor's gloss, deepening to the haze's own dark at its rim so the
// floor has no edge.
const sheenTexture = () => {
  const size = 512;
  const { element, context } = canvas(size, size);
  if (!context) return undefined;

  const middle = size / 2;
  const sheen = context.createRadialGradient(
    middle,
    middle,
    0,
    middle,
    middle,
    middle,
  );
  sheen.addColorStop(0, "rgba(2, 7, 13, 0.7)");
  sheen.addColorStop(0.45, "rgba(2, 7, 13, 0.85)");
  sheen.addColorStop(0.95, "rgba(1, 3, 7, 1)");
  context.fillStyle = sheen;
  context.fillRect(0, 0, size, size);

  return texture(element);
};

// Where the panels stand, as angles round the figure from behind it (+Z,
// the side it faces away from) and how far out: two close behind its left,
// as in the game, and a few further off so every side has some light.
const PANELS = [
  { angle: 0.22, distance: 5.6 },
  { angle: 0.45, distance: 6.2 },
  { angle: -0.6, distance: 7 },
  { angle: 1.6, distance: 7 },
  { angle: -1.7, distance: 7 },
  { angle: 2.6, distance: 7.4 },
  { angle: -2.5, distance: 7.4 },
];

// Around the figure's centre, which the viewer puts at the origin, with the
// floor at its feet.
export const buildBackdrop = (
  floor: number,
  { reflective = true }: { reflective?: boolean } = {},
) => {
  const group = new Group();
  group.position.set(0, floor, 0);
  group.userData.backdrop = true;

  const hazeMap = hazeTexture();
  const room = new Mesh(
    new SphereGeometry(BACKDROP_RADIUS, 64, 32),
    new MeshBasicMaterial({
      map: hazeMap,
      side: BackSide,
      toneMapped: false,
      depthWrite: false,
    }),
  );
  room.position.y = 1.2;
  group.add(room);

  if (reflective) {
    const mirror = new Reflector(new CircleGeometry(BACKDROP_RADIUS, 64), {
      color: new Color("#3b4a58"),
      textureWidth: 1024,
      textureHeight: 1024,
    });
    mirror.rotation.x = -Math.PI / 2;
    mirror.position.y = -0.006;
    group.add(mirror);
  } else {
    // Unlit: a lit gloss mirrors the room light's white sky and blows out.
    const ground = new Mesh(
      new CircleGeometry(BACKDROP_RADIUS, 64),
      new MeshBasicMaterial({ color: "#050c13", toneMapped: false }),
    );
    ground.rotation.x = -Math.PI / 2;
    ground.position.y = -0.006;
    group.add(ground);
  }

  // Over the mirror or the plain ground, dimming it to the gloss of a dark
  // floor.
  // Only with its gradient: untextured it would be a white disc.
  const sheenMap = sheenTexture();
  if (sheenMap) {
    const sheen = new Mesh(
      new CircleGeometry(BACKDROP_RADIUS, 64),
      new MeshBasicMaterial({
        map: sheenMap,
        transparent: true,
        depthWrite: false,
        toneMapped: false,
      }),
    );
    sheen.rotation.x = -Math.PI / 2;
    sheen.position.y = -0.004;
    group.add(sheen);
  }

  const panelMap = panelTexture();
  const haloMap = haloTexture();

  PANELS.forEach(({ angle, distance }) => {
    const x = Math.sin(angle) * distance;
    const z = Math.cos(angle) * distance;

    const stand = new Group();
    stand.position.set(x, 0, z);
    // Facing the figure.
    stand.lookAt(new Vector3(0, 0, 0));

    if (panelMap) {
      const panel = new Mesh(
        new PlaneGeometry(PANEL_WIDTH, PANEL_HEIGHT),
        new MeshBasicMaterial({
          map: panelMap,
          transparent: true,
          toneMapped: false,
          side: DoubleSide,
        }),
      );
      panel.position.y = PANEL_HEIGHT / 2 + 0.25;
      stand.add(panel);
    }

    if (haloMap) {
      const halo = new Mesh(
        new PlaneGeometry(PANEL_WIDTH * 5, PANEL_HEIGHT * 1.6),
        new MeshBasicMaterial({
          map: haloMap,
          transparent: true,
          blending: AdditiveBlending,
          depthWrite: false,
          toneMapped: false,
          side: DoubleSide,
        }),
      );
      halo.position.set(0, PANEL_HEIGHT / 2 + 0.25, -0.05);
      stand.add(halo);
    }

    group.add(stand);
  });

  return group;
};

export const disposeBackdrop = (backdrop: Object3D) => {
  const maps = new Set<Texture>();

  backdrop.traverse((node) => {
    const mesh = node as Mesh;
    if (!mesh.isMesh) return;

    mesh.geometry.dispose();
    const material = mesh.material as Material & { map?: Texture | null };
    if (material.map) maps.add(material.map);
    material.dispose();
    (mesh as unknown as { dispose?: () => void }).dispose?.();
  });

  maps.forEach((map) => map.dispose());
};
