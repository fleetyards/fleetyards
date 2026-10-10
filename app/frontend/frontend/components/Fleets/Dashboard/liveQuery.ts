// The app leaves a cached answer alone when its tab is focused again. The
// dashboard is the page somebody returns to precisely to see what changed, so
// its panels ask again.
export const liveQuery = { refetchOnWindowFocus: true } as const;
