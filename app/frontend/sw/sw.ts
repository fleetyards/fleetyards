import { cleanupOutdatedCaches, precacheAndRoute } from "workbox-precaching";
import { clientsClaim } from "workbox-core";
import type { ServiceWorkerScope } from "./types";

declare const self: ServiceWorkerScope;

// What generateSW used to write for us: precache the build, drop caches from
// older builds, and take over open tabs as soon as a new worker installs.
cleanupOutdatedCaches();
precacheAndRoute(self.__WB_MANIFEST);
void self.skipWaiting();
clientsClaim();
