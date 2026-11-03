const CHUNK_RELOAD_KEY = "fleetyards.chunkReloadAt";
export const CHUNK_RELOAD_COOLDOWN = 60_000;

const lastChunkReload = () => {
  try {
    return Number(sessionStorage.getItem(CHUNK_RELOAD_KEY)) || 0;
  } catch {
    return 0;
  }
};

// A chunk missing after a release is fixed by one reload. A chunk that fails
// every time, because it throws while evaluating or the network blocks it,
// would otherwise reload the page forever and spend the whole API rate limit
// on page boots, so a second failure soon after is left to surface instead.
export const reloadForFailedChunk = () => {
  if (Date.now() - lastChunkReload() < CHUNK_RELOAD_COOLDOWN) return false;

  try {
    sessionStorage.setItem(CHUNK_RELOAD_KEY, String(Date.now()));
  } catch {
    return false;
  }

  window.location.reload();

  return true;
};

export const handlePreloadError = (event: Event) => {
  if (reloadForFailedChunk()) event.preventDefault();
};
