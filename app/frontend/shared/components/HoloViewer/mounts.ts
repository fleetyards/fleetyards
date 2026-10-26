import { Group, type Object3D } from "three";
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";
import { sharedDracoLoader } from "./dracoLoader";

// A part drawn on a port of the holo below it: the port's place in its parent's
// frame, the part's own holo, and whatever sits on the part's ports in turn.
export type HoloMount = {
  position: [number, number, number];
  rotation: [number, number, number, number];
  path?: string;
  mounts: HoloMount[];
};

// One download per holo however many ports mount it -- a quad rack carries
// four of the same missile.
const loaded = new Map<string, Promise<Object3D>>();

const loadHolo = (path: string) => {
  let scene = loaded.get(path);

  if (!scene) {
    scene = new GLTFLoader()
      .setDRACOLoader(sharedDracoLoader())
      .loadAsync(path)
      .then((gltf) => gltf.scene);
    // A failed download is tried again by the next preview that asks for it.
    scene.catch(() => loaded.delete(path));
    loaded.set(path, scene);
  }

  return scene;
};

// The mounts as a tree of groups under one root, every holo in place. A holo
// that does not load leaves its port empty rather than failing the preview.
export const buildMounts = async (mounts: HoloMount[]) => {
  const root = new Group();

  const attach = async (parent: Object3D, list: HoloMount[]) => {
    await Promise.all(
      list.map(async (mount) => {
        const group = new Group();
        group.position.fromArray(mount.position);
        group.quaternion.fromArray(mount.rotation);
        parent.add(group);

        if (mount.path) {
          try {
            group.add((await loadHolo(mount.path)).clone(true));
          } catch (error) {
            console.warn("Loadout preview: a part's holo did not load", error);
          }
        }

        await attach(group, mount.mounts);
      }),
    );
  };

  await attach(root, mounts);

  return root;
};
