import {
  AdditiveBlending,
  type Box3,
  BufferAttribute,
  CanvasTexture,
  CircleGeometry,
  Color,
  DoubleSide,
  Group,
  LatheGeometry,
  type Material,
  Mesh,
  MeshBasicMaterial,
  type Object3D,
  SRGBColorSpace,
  type Texture,
  TorusGeometry,
  Vector2,
  Vector3,
} from "three";

const HEIGHT = 0.07;
const BEVEL = 0.018;
const SEGMENTS = 128;
// Clear of the soles, so the boots and the top never fight over one plane.
const SINK = 0.004;

// Gunmetal, painted rather than lit: the viewer's lights follow the camera
// and either sink a dark metal to black or wash it out white, and a painted
// part switches them. Drawn in, and kept out of the tone mapping, the pad
// looks the same under all of them.
const GUNMETAL = {
  sheen: "#5a636c",
  face: "#3a4249",
  edge: "#262b31",
  bevel: "#6b747d",
  side: "#343b42",
  foot: "#15191d",
};

// The pad's face: brushed gunmetal with a sheen at the heart, and the
// projector's markings over it in the holo's colour.
const faceTexture = (color: string) => {
  const size = 1024;
  const canvas = document.createElement("canvas");
  canvas.width = size;
  canvas.height = size;

  const context = canvas.getContext("2d");
  if (!context) return undefined;

  const center = size / 2;
  const { r, g, b } = new Color(color);
  const rgba = (alpha: number) =>
    `rgba(${Math.round(r * 255)}, ${Math.round(g * 255)}, ${Math.round(b * 255)}, ${alpha})`;

  const metal = context.createRadialGradient(
    center * 0.85,
    center * 0.8,
    0,
    center,
    center,
    center,
  );
  metal.addColorStop(0, GUNMETAL.sheen);
  metal.addColorStop(0.55, GUNMETAL.face);
  metal.addColorStop(1, GUNMETAL.edge);
  context.fillStyle = metal;
  context.fillRect(0, 0, size, size);

  // Brushed rings, a little lighter and darker in turn.
  for (let ring = 6; ring < center; ring += 3) {
    context.lineWidth = 1;
    context.strokeStyle =
      ring % 2 ? "rgba(255, 255, 255, 0.025)" : "rgba(0, 0, 0, 0.05)";
    context.beginPath();
    context.arc(center, center, ring, 0, Math.PI * 2);
    context.stroke();
  }

  const glow = context.createRadialGradient(
    center,
    center,
    0,
    center,
    center,
    center,
  );
  glow.addColorStop(0, rgba(0.22));
  glow.addColorStop(0.4, rgba(0.04));
  glow.addColorStop(1, rgba(0));
  context.fillStyle = glow;
  context.fillRect(0, 0, size, size);

  context.strokeStyle = rgba(0.35);
  [0.32, 0.6].forEach((radius) => {
    context.lineWidth = 2;
    context.beginPath();
    context.arc(center, center, center * radius, 0, Math.PI * 2);
    context.stroke();
  });

  context.lineWidth = 3;
  context.strokeStyle = rgba(0.75);
  context.beginPath();
  context.arc(center, center, center * 0.86, 0, Math.PI * 2);
  context.stroke();

  for (let tick = 0; tick < 72; tick += 1) {
    const angle = (tick / 72) * Math.PI * 2;
    const long = tick % 6 === 0;
    const inner = center * (long ? 0.88 : 0.9);
    const outer = center * 0.95;
    context.lineWidth = long ? 3 : 1.5;
    context.strokeStyle = rgba(long ? 0.8 : 0.45);
    context.beginPath();
    context.moveTo(
      center + Math.cos(angle) * inner,
      center + Math.sin(angle) * inner,
    );
    context.lineTo(
      center + Math.cos(angle) * outer,
      center + Math.sin(angle) * outer,
    );
    context.stroke();
  }

  const texture = new CanvasTexture(canvas);
  texture.colorSpace = SRGBColorSpace;
  texture.anisotropy = 4;

  return texture;
};

// The disc's bevel and side, shaded from a light band at the bevel to a dark
// foot, as a metal rim catches a light from above.
const shadeSide = (geometry: LatheGeometry) => {
  const positions = geometry.getAttribute("position");
  const colors = new Float32Array(positions.count * 3);
  const bevel = new Color(GUNMETAL.bevel);
  const side = new Color(GUNMETAL.side);
  const foot = new Color(GUNMETAL.foot);
  const shade = new Color();

  for (let index = 0; index < positions.count; index += 1) {
    const depth = -positions.getY(index);

    if (depth <= BEVEL) {
      shade.copy(bevel);
    } else {
      shade.lerpColors(side, foot, (depth - BEVEL) / (HEIGHT - BEVEL));
    }

    shade.toArray(colors, index * 3);
  }

  geometry.setAttribute("color", new BufferAttribute(colors, 3));
};

// A bevelled gunmetal disc a little wider than the figure's stance, its face
// a holo projector pad and its rim lit in the holo's colour.
export const buildPedestal = (figure: Box3, color: string) => {
  const size = figure.getSize(new Vector3());
  const center = figure.getCenter(new Vector3());
  const radius = (Math.max(size.x, size.z) / 2) * 1.35;

  const group = new Group();
  group.position.set(center.x, figure.min.y - SINK, center.z);

  // Profile from the axis out: the top, the bevel, the side, and back in.
  const profile = [
    new Vector2(0, 0),
    new Vector2(radius - BEVEL, 0),
    new Vector2(radius, -BEVEL),
    new Vector2(radius * 1.02, -HEIGHT),
    new Vector2(0, -HEIGHT),
  ];
  const geometry = new LatheGeometry(profile, SEGMENTS);
  shadeSide(geometry);

  const parts: Object3D[] = [
    new Mesh(
      geometry,
      new MeshBasicMaterial({ vertexColors: true, toneMapped: false }),
    ),
  ];

  const texture = faceTexture(color);
  if (texture) {
    const face = new Mesh(
      new CircleGeometry(radius - BEVEL, SEGMENTS),
      new MeshBasicMaterial({ map: texture, toneMapped: false }),
    );
    face.rotation.x = -Math.PI / 2;
    face.position.y = 0.0015;
    parts.push(face);
  }

  // A thin lit band where the bevel meets the side, and a soft halo around it.
  [
    { tube: 0.0035, opacity: 1 },
    { tube: 0.014, opacity: 0.18 },
  ].forEach(({ tube, opacity }) => {
    const ring = new Mesh(
      new TorusGeometry(radius, tube, 12, SEGMENTS),
      new MeshBasicMaterial({
        color,
        transparent: opacity < 1,
        opacity,
        blending: opacity < 1 ? AdditiveBlending : undefined,
        depthWrite: opacity >= 1,
        side: DoubleSide,
      }),
    );
    ring.rotation.x = -Math.PI / 2;
    ring.position.y = -BEVEL;
    parts.push(ring);
  });

  group.add(...parts);
  group.userData.pedestal = true;

  return group;
};

export const disposePedestal = (pedestal: Object3D) => {
  pedestal.traverse((node) => {
    const mesh = node as Mesh;
    if (!mesh.isMesh) return;

    mesh.geometry.dispose();
    const material = mesh.material as Material & { map?: Texture | null };
    material.map?.dispose();
    material.dispose();
  });
};
