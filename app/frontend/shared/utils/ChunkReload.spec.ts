import {
  CHUNK_RELOAD_COOLDOWN,
  handlePreloadError,
  reloadForFailedChunk,
} from "@/shared/utils/ChunkReload";

describe("reloadForFailedChunk", () => {
  const reload = vi.fn();

  beforeEach(() => {
    sessionStorage.clear();
    reload.mockReset();
    vi.stubGlobal("location", { ...window.location, reload });
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
  });

  it("reloads on the first failure", () => {
    expect(reloadForFailedChunk()).toBe(true);
    expect(reload).toHaveBeenCalledTimes(1);
  });

  it("does not reload again while the last reload is recent", () => {
    reloadForFailedChunk();
    vi.advanceTimersByTime(CHUNK_RELOAD_COOLDOWN - 1);

    expect(reloadForFailedChunk()).toBe(false);
    expect(reload).toHaveBeenCalledTimes(1);
  });

  it("reloads again once the cooldown has passed", () => {
    reloadForFailedChunk();
    vi.advanceTimersByTime(CHUNK_RELOAD_COOLDOWN);

    expect(reloadForFailedChunk()).toBe(true);
    expect(reload).toHaveBeenCalledTimes(2);
  });

  it("does not reload when the attempt cannot be remembered", () => {
    vi.spyOn(Storage.prototype, "setItem").mockImplementation(() => {
      throw new Error("blocked");
    });

    expect(reloadForFailedChunk()).toBe(false);
    expect(reload).not.toHaveBeenCalled();
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
    const first = new Event("vite:preloadError", { cancelable: true });
    handlePreloadError(first);
    expect(first.defaultPrevented).toBe(true);

    const second = new Event("vite:preloadError", { cancelable: true });
    handlePreloadError(second);
    expect(second.defaultPrevented).toBe(false);
  });
});
