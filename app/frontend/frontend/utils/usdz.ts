import { type Material, type Mesh, type Object3D, type Texture } from "three";
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";
import { USDZExporter } from "three/examples/jsm/exporters/USDZExporter.js";
import { sharedDracoLoader } from "@/shared/components/HoloViewer/dracoLoader";

const disposeMaterial = (material: Material) => {
  for (const value of Object.values(material)) {
    if ((value as Texture | null)?.isTexture) (value as Texture).dispose();
  }

  material.dispose();
};

const dispose = (scene: Object3D) => {
  scene.traverse((node) => {
    const mesh = node as Mesh;

    if (!mesh.isMesh) return;

    mesh.geometry.dispose();

    const materials = Array.isArray(mesh.material)
      ? mesh.material
      : [mesh.material];
    materials.forEach(disposeMaterial);
  });
};

// Decoded with the 3D view's own decoder: a second pool of wasm workers, each
// grown to the size of the largest holo it has seen, is what an iPhone could
// not hold on a second tap.
export const holoToUsdz = async (holoUrl: string): Promise<Blob> => {
  const loader = new GLTFLoader().setDRACOLoader(sharedDracoLoader());
  const { scene } = await loader.loadAsync(holoUrl);

  // The exporter writes each node's local matrix, which the loader leaves
  // unset for a node given as translation, rotation and scale.
  scene.updateMatrixWorld(true);

  try {
    const buffer = await new USDZExporter().parseAsync(scene, {
      quickLookCompatible: true,
    });

    return new Blob([buffer], { type: "model/vnd.usdz+zip" });
  } finally {
    dispose(scene);
  }
};
