import {
  CHUNK_RELOAD_COOLDOWN,
  chunkLoadFailures,
  handlePreloadError,
  reloadForFailedChunk,
} from "@/shared/utils/ChunkReload";

const CHUNK_RELOAD_KEY = "fleetyards.chunkReloadAt";

const documentStart = Math.ceil(performance.timeOrigin);

const reloadedByEarlierDocument = (msAgo = 1) =>
  sessionStorage.setItem(CHUNK_RELOAD_KEY, String(documentStart - msAgo));

describe("reloadForFailedChunk", () => {
  const reload = vi.fn();

  beforeEach(() => {
    sessionStorage.clear();
    chunkLoadFailures.value = 0;
    reload.mockReset();
    vi.stubGlobal("location", { ...window.location, reload });
    vi.useFakeTimers({ toFake: ["Date"] });
    vi.setSystemTime(documentStart);
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
  });

  it("reloads on the first failure", () => {
    expect(reloadForFailedChunk()).toBe(true);
    expect(reload).toHaveBeenCalledTimes(1);
    expect(chunkLoadFailures.value).toBe(0);
  });

  it("treats more failures while its own reload is under way as handled", () => {
    reloadForFailedChunk();

    expect(reloadForFailedChunk()).toBe(true);
    expect(reload).toHaveBeenCalledTimes(1);
    expect(chunkLoadFailures.value).toBe(0);
  });

  it("does not reload again soon after an earlier document's reload", () => {
    reloadedByEarlierDocument();

    expect(reloadForFailedChunk()).toBe(false);
    expect(reload).not.toHaveBeenCalled();
  });

  it("counts a failure the cooldown keeps from reloading", () => {
    reloadedByEarlierDocument();

    reloadForFailedChunk();
    reloadForFailedChunk();

    expect(chunkLoadFailures.value).toBe(2);
  });

  it("reloads again once the cooldown has passed", () => {
    reloadedByEarlierDocument(CHUNK_RELOAD_COOLDOWN);

    expect(reloadForFailedChunk()).toBe(true);
    expect(reload).toHaveBeenCalledTimes(1);
  });

  it("does not reload when the attempt cannot be remembered", () => {
    vi.spyOn(Storage.prototype, "setItem").mockImplementation(() => {
      throw new Error("blocked");
    });

    expect(reloadForFailedChunk()).toBe(false);
    expect(reload).not.toHaveBeenCalled();
    expect(chunkLoadFailures.value).toBe(1);
  });
});

describe("handlePreloadError", () => {
  beforeEach(() => {
    sessionStorage.clear();
    vi.stubGlobal("location", { ...window.location, reload: vi.fn() });
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("swallows the error only when it reloads", () => {
    const reloading = new Event("vite:preloadError", { cancelable: true });
    handlePreloadError(reloading);
    expect(reloading.defaultPrevented).toBe(true);

    sessionStorage.setItem(CHUNK_RELOAD_KEY, String(documentStart - 1));
    vi.spyOn(Date, "now").mockReturnValue(documentStart);
    const stuck = new Event("vite:preloadError", { cancelable: true });
    handlePreloadError(stuck);
    expect(stuck.defaultPrevented).toBe(false);
    vi.restoreAllMocks();
  });
});
