import { DRACOLoader } from "three/examples/jsm/loaders/DRACOLoader.js";
import { isLowPowerDevice } from "@/shared/composables/useLowPowerDevice";

// One decoder for every holo. Each DRACOLoader keeps its own worker pool, each
// worker with its own copy of the wasm decoder, and nothing disposes one -- a
// loader per mount piled them up with every open of the 3D view and every
// flight/landed switch, which a phone does not survive for long.
let dracoLoader: DRACOLoader | undefined;

export const sharedDracoLoader = () => {
  dracoLoader ??= new DRACOLoader()
    .setDecoderPath("https://www.gstatic.com/draco/versioned/decoders/1.5.7/")
    // A phone decodes one holo at a time; the multi-ship viewer on a desktop
    // decodes several side by side.
    .setWorkerLimit(isLowPowerDevice() ? 1 : 4);

  return dracoLoader;
};
