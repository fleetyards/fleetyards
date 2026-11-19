import type { BufferGeometry } from "three";
import { DRACOLoader } from "three/examples/jsm/loaders/DRACOLoader.js";
import { isLowPowerDevice } from "@/shared/composables/useLowPowerDevice";

// three's typings leave out the method every decode goes through.
type DecodeGeometry = (
  buffer: ArrayBuffer,
  taskConfig: object,
) => Promise<BufferGeometry>;

const baseDecodeGeometry = () =>
  (DRACOLoader.prototype as unknown as { decodeGeometry: DecodeGeometry })
    .decodeGeometry;

// A mesh the wasm decoder cannot fit in its 2 GB heap aborts it, and an
// aborted decoder keeps that heap and fails every decode after: the lite
// export of the same ship included. A failure retires the loader, so the next
// holo starts on fresh workers, and the old ones go once their last task ends.
class RecyclingDracoLoader extends DRACOLoader {
  private pending = 0;
  private retired = false;
  private disposed = false;

  decodeGeometry(
    buffer: ArrayBuffer,
    taskConfig: object,
  ): Promise<BufferGeometry> {
    // A GLTFLoader set up before the failure still holds this one.
    if (this.disposed) {
      return sharedDracoLoader().decodeGeometry(buffer, taskConfig);
    }

    this.pending++;

    return baseDecodeGeometry()
      .call(this, buffer, taskConfig)
      .catch((error: unknown) => {
        this.retire();
        throw error;
      })
      .finally(() => {
        this.pending--;
        if (this.retired && this.pending === 0 && !this.disposed) {
          this.disposed = true;
          this.dispose();
        }
      });
  }

  private retire() {
    this.retired = true;
    if (dracoLoader === this) dracoLoader = undefined;
  }
}

// One decoder for every holo. Each DRACOLoader keeps its own worker pool, each
// worker with its own copy of the wasm decoder, and nothing disposes one -- a
// loader per mount piled them up with every open of the 3D view and every
// flight/landed switch, which a phone does not survive for long.
let dracoLoader: RecyclingDracoLoader | undefined;

export const sharedDracoLoader = (): RecyclingDracoLoader => {
  dracoLoader ??= new RecyclingDracoLoader()
    .setDecoderPath("https://www.gstatic.com/draco/versioned/decoders/1.5.7/")
    // A phone decodes one holo at a time; the multi-ship viewer on a desktop
    // decodes several side by side.
    .setWorkerLimit(isLowPowerDevice() ? 1 : 4);

  return dracoLoader;
};

// The worker posts its failure as a plain object, not an Error.
export const dracoErrorMessage = (error: unknown): string | undefined => {
  if (
    typeof error === "object" &&
    error !== null &&
    "type" in error &&
    error.type === "error" &&
    "error" in error &&
    typeof error.error === "string"
  ) {
    return error.error;
  }

  return undefined;
};
