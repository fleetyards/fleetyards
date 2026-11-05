import { ref } from "vue";

const CHUNK_RELOAD_KEY = "fleetyards.chunkReloadAt";
export const CHUNK_RELOAD_COOLDOWN = 60_000;

// A failed chunk cannot be retried inside its document: Vite never requests a
// stylesheet twice, so the next attempt succeeds with the page left unstyled,
// and WebKit answers every later import of the module with the same failure.
// Loading the document again recovers, except that WebKit can keep failing the
// module for as long as the tab lives, which in an installed app means until it
// is closed.
export const chunkLoadFailed = ref(false);

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
  if (Date.now() - lastChunkReload() < CHUNK_RELOAD_COOLDOWN) {
    chunkLoadFailed.value = true;
    return false;
  }

  try {
    sessionStorage.setItem(CHUNK_RELOAD_KEY, String(Date.now()));
  } catch {
    chunkLoadFailed.value = true;
    return false;
  }

  window.location.reload();

  return true;
};

export const handlePreloadError = (event: Event) => {
  if (reloadForFailedChunk()) event.preventDefault();
};
