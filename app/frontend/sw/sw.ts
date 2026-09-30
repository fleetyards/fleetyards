import { cleanupOutdatedCaches, precacheAndRoute } from "workbox-precaching";
import { clientsClaim } from "workbox-core";
import icon from "../images/favicons/icon-192.png";
import {
  notificationOptions,
  parsePushPayload,
  pickClient,
  safeUrl,
} from "./push";
import type { ServiceWorkerScope } from "./types";

declare const self: ServiceWorkerScope;

// What generateSW used to write for us: precache the build, drop caches from
// older builds, and take over open tabs as soon as a new worker installs.
cleanupOutdatedCaches();
precacheAndRoute(self.__WB_MANIFEST);
void self.skipWaiting();
clientsClaim();

// A deploy can activate a new worker mid-session, so nothing below may depend
// on the build that queued the push.
self.addEventListener("push", (event) => {
  const payload = parsePushPayload(event.data?.text());

  event.waitUntil(
    self.registration.showNotification(
      payload.title,
      notificationOptions(payload, self.location.origin, icon),
    ),
  );
});

// Only for a push: the app's own local alerts go through this registration
// too, carry no link, and clicking one never did anything but close it.
self.addEventListener("notificationclick", (event) => {
  event.notification.close();

  const link = event.notification.data?.url;
  if (!link) return;

  const origin = self.location.origin;
  const url = safeUrl(link, origin);

  event.waitUntil(
    (async () => {
      const windows = await self.clients.matchAll({
        type: "window",
        includeUncontrolled: true,
      });
      const target = pickClient(windows, url, origin);

      if (!target) {
        await self.clients.openWindow(url);
        return;
      }

      const focused = await target.client.focus();
      if (target.navigate) await focused.navigate(url);
    })(),
  );
});

// The browser rotated the subscription. Without telling the server, push to
// this device simply stops. The new keys come along, which is what lets the
// server accept the endpoint for this account.
//
// This needs a session, and the worker may run with none. A refused save is
// thrown rather than swallowed; the app posts its current subscription again
// on the next signed-in visit, which is what recovers it.
self.addEventListener("pushsubscriptionchange", (event) => {
  event.waitUntil(
    (async () => {
      const subscription =
        event.newSubscription ??
        (await self.registration.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey:
            event.oldSubscription?.options.applicationServerKey,
        }));

      const response = await fetch("/api/v1/push-subscriptions", {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(subscription.toJSON()),
      });

      if (!response.ok) {
        throw new Error(`push subscription not saved: ${response.status}`);
      }
    })(),
  );
});
