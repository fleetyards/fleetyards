// The slice of the service worker globals this worker uses. The project's
// TypeScript config targets the DOM, and the WebWorker lib cannot be loaded
// alongside it without conflicting declarations.
import type { PrecacheEntry } from "workbox-precaching";

export interface ServiceWorkerScope {
  __WB_MANIFEST: Array<PrecacheEntry | string>;
  skipWaiting(): Promise<void>;
}
