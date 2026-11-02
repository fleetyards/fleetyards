import {
  AdditiveBlending,
  type Box3,
  CanvasTexture,
  CircleGeometry,
  Color,
  DoubleSide,
  Group,
  LatheGeometry,
  type Material,
  Mesh,
  MeshBasicMaterial,
  MeshPhongMaterial,
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

// The projector pad's face: a glow at the heart, faint rings and a ring of
// ticks at the edge, in the holo's colour on transparency.
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

  const glow = context.createRadialGradient(
    center,
    center,
    0,
    center,
    center,
    center,
  );
  glow.addColorStop(0, rgba(0.35));
  glow.addColorStop(0.45, rgba(0.08));
  glow.addColorStop(1, rgba(0));
  context.fillStyle = glow;
  context.fillRect(0, 0, size, size);

  context.strokeStyle = rgba(0.45);
  [0.32, 0.6].forEach((radius) => {
    context.lineWidth = 2;
    context.beginPath();
    context.arc(center, center, center * radius, 0, Math.PI * 2);
    context.stroke();
  });

  context.lineWidth = 3;
  context.strokeStyle = rgba(0.7);
  context.beginPath();
  context.arc(center, center, center * 0.86, 0, Math.PI * 2);
  context.stroke();

  for (let tick = 0; tick < 72; tick += 1) {
    const angle = (tick / 72) * Math.PI * 2;
    const long = tick % 6 === 0;
    const inner = center * (long ? 0.88 : 0.9);
    const outer = center * 0.95;
    context.lineWidth = long ? 3 : 1.5;
    context.strokeStyle = rgba(long ? 0.75 : 0.4);
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

// A bevelled metal disc a little wider than the figure's stance, its face a
// holo projector pad and its rim lit in the holo's colour.
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
  const base = new Mesh(
    new LatheGeometry(profile, SEGMENTS),
    // Phong ignores the scene's environment, so the pad looks the same
    // whether or not a painted part brings the room light with it.
    new MeshPhongMaterial({
      color: "#15191e",
      specular: "#3d4650",
      shininess: 60,
    }),
  );

  const parts: Object3D[] = [base];

  const texture = faceTexture(color);
  if (texture) {
    const face = new Mesh(
      new CircleGeometry(radius - BEVEL, SEGMENTS),
      new MeshBasicMaterial({
        map: texture,
        transparent: true,
        depthWrite: false,
      }),
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
