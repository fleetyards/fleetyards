import { BufferGeometry } from "three";
import { DRACOLoader } from "three/examples/jsm/loaders/DRACOLoader.js";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const abort = {
  type: "error",
  error: "Aborted(). Build with -sASSERTIONS for more info.",
};

const taskConfig = {
  attributeIDs: {},
  attributeTypes: {},
  useUniqueIDs: false,
  vertexColorSpace: "",
};

const deferred = () => {
  let resolve!: (geometry: BufferGeometry) => void;
  let reject!: (error: unknown) => void;
  const promise = new Promise<BufferGeometry>((res, rej) => {
    resolve = res;
    reject = rej;
  });

  return { promise, resolve, reject };
};

describe("sharedDracoLoader", () => {
  let decode: ReturnType<typeof vi.spyOn>;
  let dispose: ReturnType<typeof vi.spyOn>;

  beforeEach(() => {
    vi.resetModules();
    decode = vi.spyOn(
      DRACOLoader.prototype as unknown as {
        decodeGeometry: (...args: unknown[]) => Promise<BufferGeometry>;
      },
      "decodeGeometry",
    );
    dispose = vi
      .spyOn(DRACOLoader.prototype, "dispose")
      .mockImplementation(function (this: DRACOLoader) {
        return this;
      });
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  const load = async () => (await import("./dracoLoader")).sharedDracoLoader;

  it("keeps one loader while decodes succeed", async () => {
    const sharedDracoLoader = await load();
    decode.mockResolvedValue(new BufferGeometry());

    const loader = sharedDracoLoader();
    await loader.decodeGeometry(new ArrayBuffer(0), taskConfig);

    expect(sharedDracoLoader()).toBe(loader);
    expect(dispose).not.toHaveBeenCalled();
  });

  it("hands out a fresh loader once a decode aborts", async () => {
    const sharedDracoLoader = await load();
    decode.mockRejectedValue(abort);

    const loader = sharedDracoLoader();
    await expect(
      loader.decodeGeometry(new ArrayBuffer(0), taskConfig),
    ).rejects.toBe(abort);

    expect(sharedDracoLoader()).not.toBe(loader);
    expect(dispose).toHaveBeenCalledOnce();
  });

  it("lets the old loader's other decodes finish before disposing it", async () => {
    const sharedDracoLoader = await load();
    const other = deferred();
    decode.mockReturnValueOnce(other.promise).mockRejectedValueOnce(abort);

    const loader = sharedDracoLoader();
    const running = loader.decodeGeometry(new ArrayBuffer(0), taskConfig);
    await expect(
      loader.decodeGeometry(new ArrayBuffer(0), taskConfig),
    ).rejects.toBe(abort);

    expect(dispose).not.toHaveBeenCalled();

    other.resolve(new BufferGeometry());
    await running;

    expect(dispose).toHaveBeenCalledOnce();
  });

  it("sends a decode on a retired loader to the fresh one at once", async () => {
    const sharedDracoLoader = await load();
    const other = deferred();
    decode.mockReturnValueOnce(other.promise).mockRejectedValueOnce(abort);

    const old = sharedDracoLoader();
    const running = old.decodeGeometry(new ArrayBuffer(0), taskConfig);
    await expect(
      old.decodeGeometry(new ArrayBuffer(0), taskConfig),
    ).rejects.toBe(abort);

    decode.mockResolvedValueOnce(new BufferGeometry());
    await old.decodeGeometry(new ArrayBuffer(0), taskConfig);

    expect(decode.mock.contexts.at(-1)).toBe(sharedDracoLoader());
    expect(dispose).not.toHaveBeenCalled();

    other.resolve(new BufferGeometry());
    await running;
    expect(dispose).toHaveBeenCalledOnce();
  });

  it("still disposes once a decode threw before it began", async () => {
    const sharedDracoLoader = await load();
    decode.mockImplementationOnce(() => {
      throw new Error("Unable to re-decode a buffer with different settings.");
    });

    const loader = sharedDracoLoader();
    await expect(
      loader.decodeGeometry(new ArrayBuffer(0), taskConfig),
    ).rejects.toThrow("re-decode");

    expect(dispose).toHaveBeenCalledOnce();
    expect(sharedDracoLoader()).not.toBe(loader);
  });

  it("sends a decode on a disposed loader to the fresh one", async () => {
    const sharedDracoLoader = await load();
    decode.mockRejectedValueOnce(abort);

    const old = sharedDracoLoader();
    await expect(
      old.decodeGeometry(new ArrayBuffer(0), taskConfig),
    ).rejects.toBe(abort);

    const geometry = new BufferGeometry();
    decode.mockResolvedValueOnce(geometry);

    await expect(
      old.decodeGeometry(new ArrayBuffer(0), taskConfig),
    ).resolves.toBe(geometry);
    expect(decode.mock.contexts.at(-1)).toBe(sharedDracoLoader());
  });
});

describe("dracoErrorMessage", () => {
  it("reads the message off the worker's error", async () => {
    const { dracoErrorMessage } = await import("./dracoLoader");

    expect(dracoErrorMessage(abort)).toBe(abort.error);
  });

  it("ignores anything else", async () => {
    const { dracoErrorMessage } = await import("./dracoLoader");

    expect(dracoErrorMessage(new Error("network"))).toBeUndefined();
    expect(dracoErrorMessage("/holo.glb")).toBeUndefined();
    expect(dracoErrorMessage(undefined)).toBeUndefined();
  });
});
