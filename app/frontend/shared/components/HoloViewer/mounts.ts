import {
  Group,
  type Material,
  type Mesh,
  type Object3D,
  type Texture,
} from "three";
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";
import { extrasLoadingManager, prepareGltfLoader } from "./gltfLoader";

// A part drawn on a port of the holo below it: the port's place in its parent's
// frame, the part's own holo, and whatever sits on the part's ports in turn.
export type HoloMount = {
  position: [number, number, number];
  rotation: [number, number, number, number];
  path?: string;
  // Bytes, where the file is known: a phone asks before loading a large one.
  size?: number;
  // Painted: drawn with its own materials, not the holo's.
  textured?: boolean;
  // Loaded in place of a painted holo that does not load, and drawn plain.
  fallbackPath?: string;
  // What the viewer names this part by when it is clicked.
  id?: string;
  // Drawn in the highlight colour, with everything mounted on it.
  highlighted?: boolean;
  // Drawn in this colour, with whatever is mounted on it that has none.
  color?: string;
  mounts: HoloMount[];
};

// What the parts are and where they sit, without what is highlighted: a change
// here is a different fitting and rebuilds the parts.
export const mountsLayoutKey = (mounts: HoloMount[] = []): string =>
  mounts
    .map(
      (mount) =>
        `${mount.path ?? ""}@${mount.position.join(",")}/${mount.rotation.join(",")}(${mountsLayoutKey(mount.mounts)})`,
    )
    .join(";");

export const mountsTextured = (mounts: HoloMount[] = []): boolean =>
  mounts.some((mount) => mount.textured || mountsTextured(mount.mounts));

export const mountsSize = (mounts: HoloMount[] = []): number =>
  mounts.reduce(
    (sum, mount) => sum + (mount.size ?? 0) + mountsSize(mount.mounts),
    0,
  );

// Only what is highlighted and coloured, by place in the tree: a change here
// only repaints.
export const mountsHighlightKey = (mounts: HoloMount[] = []): string =>
  mounts
    .map(
      (mount) =>
        `${mount.highlighted ? 1 : 0}${mount.color ?? ""}(${mountsHighlightKey(mount.mounts)})`,
    )
    .join("");

// One download per holo however many ports mount it -- a quad rack carries
// four of the same missile -- kept while any viewer draws parts.
const loaded = new Map<string, Promise<Object3D>>();

let viewers = 0;

export const retainMountCache = () => {
  viewers += 1;
};

// A painted part keeps the maps it was exported with, which a material's own
// dispose leaves on the GPU.
export const disposeTextures = (material: Material) => {
  for (const value of Object.values(material)) {
    if ((value as Texture | null)?.isTexture) (value as Texture).dispose();
  }
};

// The last viewer gone, the downloads go too: a long session browsing loadouts
// would otherwise keep every part it ever showed.
export const releaseMountCache = () => {
  viewers = Math.max(0, viewers - 1);
  if (viewers) return;

  const scenes = [...loaded.values()];
  loaded.clear();

  for (const scene of scenes) {
    void scene
      .then((object) =>
        object.traverse((node) => {
          const mesh = node as Mesh;
          if (!mesh.isMesh) return;

          mesh.geometry.dispose();
          for (const material of ([] as Material[]).concat(mesh.material)) {
            disposeTextures(material);
            material.dispose();
          }
        }),
      )
      .catch(() => undefined);
  }
};

export const loadHolo = (path: string) => {
  let scene = loaded.get(path);

  if (!scene) {
    scene = prepareGltfLoader(new GLTFLoader(extrasLoadingManager))
      .loadAsync(path)
      .then((gltf) => gltf.scene);
    // A failed download is tried again by the next preview that asks for it.
    scene.catch(() => loaded.delete(path));
    loaded.set(path, scene);
  }

  return scene;
};

// A clone shares the cached holo's geometry and materials; whoever restyles it
// must leave those for the cache to free.
export const cloneShared = (scene: Object3D) => {
  const clone = scene.clone(true);

  clone.traverse((node) => {
    node.userData.shared = true;
  });

  return clone;
};

// The mounts as a tree of groups under one root, every holo in place. A holo
// that does not load leaves its port empty rather than failing the preview.
export const buildMounts = async (mounts: HoloMount[]) => {
  const root = new Group();
  root.userData.mountGroups = [];

  const attach = async (parent: Object3D, list: HoloMount[]) => {
    await Promise.all(
      list.map(async (mount) => {
        const group = new Group();
        group.position.fromArray(mount.position);
        group.quaternion.fromArray(mount.rotation);
        group.userData.highlighted = !!mount.highlighted;
        group.userData.mountId = mount.id;
        group.userData.color = mount.color;
        group.userData.textured = !!mount.textured;
        group.userData.mountGroups = [];
        parent.add(group);
        // In list order, before anything is awaited, so a repaint can walk the
        // groups alongside the mounts.
        parent.userData.mountGroups.push(group);

        if (mount.path) {
          try {
            group.add(cloneShared(await loadHolo(mount.path)));
          } catch (error) {
            if (mount.fallbackPath) {
              try {
                group.add(cloneShared(await loadHolo(mount.fallbackPath)));
                group.userData.textured = false;
              } catch (fallbackError) {
                console.warn("A part's holo did not load", fallbackError);
              }
            } else {
              console.warn("A part's holo did not load", error);
            }
          }
        }

        await attach(group, mount.mounts);
      }),
    );
  };

  await attach(root, mounts);

  return root;
};

// Marks the groups a built tree holds with the mounts' highlights, colours and
// ids.
export const applyHighlights = (root: Object3D, mounts: HoloMount[]) => {
  const walk = (parent: Object3D, list: HoloMount[]) => {
    const groups: Object3D[] = parent.userData.mountGroups ?? [];

    list.forEach((mount, index) => {
      const group = groups[index];
      if (!group) return;

      group.userData.highlighted = !!mount.highlighted;
      group.userData.mountId = mount.id;
      group.userData.color = mount.color;
      walk(group, mount.mounts);
    });
  };

  walk(root, mounts);
};
