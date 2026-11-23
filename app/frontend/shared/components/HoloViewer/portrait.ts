import {
  Box3,
  type Bone,
  type Object3D,
  PerspectiveCamera,
  type Scene,
  Vector3,
  type WebGLRenderer,
} from "three";

export type PortraitOptions = {
  size?: number;
  azimuth?: number;
  elevation?: number;
  // Painted behind the figure: a transparent avatar reads as a hole on the
  // lists that draw it on a dark tile.
  background?: [inner: string, outer: string];
};

const PORTRAIT_FOV = 30;

// Head and shoulders, in the figure's metres.
const PORTRAIT_HEIGHT = 0.72;

// The frame sits a little under the head bone, so the shoulders come in.
const PORTRAIT_DROP = 0.14;

const DEFAULT_BACKGROUND: [string, string] = ["#2a3038", "#0d1013"];

// The head bone of a rigged figure; without one, a point just under the top
// of what is drawn. Matched by its whole name: the rig has helpers such as
// `Head_LowPass` that sit at the root, not on the head.
export const portraitFocus = (root: Object3D) => {
  let head: Object3D | undefined;
  root.traverse((object) => {
    if (!head && (object as Bone).isBone && /^head$/i.test(object.name)) {
      head = object;
    }
  });

  root.updateMatrixWorld(true);

  if (head) return head.getWorldPosition(new Vector3());

  const box = new Box3().setFromObject(root);
  const height = box.max.y - box.min.y;

  return new Vector3(
    (box.min.x + box.max.x) / 2,
    box.max.y - height * 0.07,
    (box.min.z + box.max.z) / 2,
  );
};

// A camera on a square looking at the head from where the viewer stands. The
// canvas is rarely square, so the camera frames the square cut from its
// middle: its short side holds the portrait.
export const portraitCamera = (
  focus: Vector3,
  aspect: number,
  azimuthDegrees = 180,
  elevationDegrees = 5,
) => {
  const fov = (PORTRAIT_FOV * Math.PI) / 180;
  const target = focus.clone().setY(focus.y - PORTRAIT_DROP);
  const distance = PORTRAIT_HEIGHT / 2 / Math.tan(fov / 2);

  const visibleHeight = PORTRAIT_HEIGHT * Math.max(1, 1 / aspect);
  const cameraFov =
    (2 * Math.atan(visibleHeight / 2 / distance) * 180) / Math.PI;

  const azimuth = (azimuthDegrees * Math.PI) / 180;
  const elevation = (elevationDegrees * Math.PI) / 180;

  const camera = new PerspectiveCamera(cameraFov, aspect, 0.01, 100);
  camera.position.set(
    target.x + Math.sin(azimuth) * Math.cos(elevation) * distance,
    target.y + Math.sin(elevation) * distance,
    target.z + Math.cos(azimuth) * Math.cos(elevation) * distance,
  );
  camera.lookAt(target);
  camera.updateProjectionMatrix();

  return camera;
};

// Draws one frame through the portrait camera and copies it out straight
// away: the drawing buffer is not preserved, so it is only readable until
// the browser composites.
export const renderPortrait = (
  renderer: WebGLRenderer,
  scene: Scene,
  figure: Object3D,
  {
    size = 512,
    azimuth,
    elevation,
    background = DEFAULT_BACKGROUND,
  }: PortraitOptions = {},
): Promise<Blob | null> => {
  const source = renderer.domElement;
  const camera = portraitCamera(
    portraitFocus(figure),
    source.width / source.height,
    azimuth,
    elevation,
  );

  renderer.render(scene, camera);

  const out = document.createElement("canvas");
  out.width = size;
  out.height = size;
  const context = out.getContext("2d");
  if (!context) return Promise.resolve(null);

  const gradient = context.createRadialGradient(
    size / 2,
    size * 0.4,
    0,
    size / 2,
    size / 2,
    size * 0.75,
  );
  gradient.addColorStop(0, background[0]);
  gradient.addColorStop(1, background[1]);
  context.fillStyle = gradient;
  context.fillRect(0, 0, size, size);

  const side = Math.min(source.width, source.height);
  context.drawImage(
    source,
    (source.width - side) / 2,
    (source.height - side) / 2,
    side,
    side,
    0,
    0,
    size,
    size,
  );

  return new Promise((resolve) => out.toBlob(resolve, "image/png"));
};
