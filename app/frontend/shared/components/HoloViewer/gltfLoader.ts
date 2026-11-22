import { LoadingManager, TextureLoader } from "three";
import type { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";
import { MeshoptDecoder } from "three/examples/jsm/libs/meshopt_decoder.module.js";
import { dequantizeSkins } from "./dequantize";
import { sharedDracoLoader } from "./dracoLoader";

// Chrome's default reads the images packed into a .glb with fetch() on a blob:
// URL, which the content security policy's connect-src refuses: every texture
// failed and a textured holo glowed white from its emissive factor. An <img>
// is let through by img-src, and is what Safari and Firefox load with anyway.
const IMAGE_ELEMENT_TEXTURES = "FLEETYARDS_image_element_textures";

const DEQUANTIZED_SKINS = "FLEETYARDS_dequantized_skins";

// Draco or meshopt, whichever the holo was exported with.
export const prepareGltfLoader = (loader: GLTFLoader) =>
  loader
    .setDRACOLoader(sharedDracoLoader())
    .setMeshoptDecoder(MeshoptDecoder)
    .register((parser) => {
      parser.textureLoader = new TextureLoader(parser.options.manager)
        .setCrossOrigin(parser.options.crossOrigin)
        .setRequestHeader(parser.options.requestHeader);

      return { name: IMAGE_ELEMENT_TEXTURES };
    })
    .register(() => ({
      name: DEQUANTIZED_SKINS,
      afterRoot: async (gltf) => dequantizeSkins(gltf.scene),
    }));

// For everything a holo loads besides the model itself, which has a manager of
// its own whose failures fail the model: a part or a paint map that failed would
// read as the whole model failing, after the caller had already dropped the part.
export const extrasLoadingManager = new LoadingManager();
