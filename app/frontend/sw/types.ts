// The slice of the service worker globals this worker uses. The project's
// TypeScript config targets the DOM, and the WebWorker lib cannot be loaded
// alongside it without conflicting declarations.
import type { PrecacheEntry } from "workbox-precaching";

export interface ExtendableEvent extends Event {
  waitUntil(promise: Promise<unknown>): void;
}

export interface PushEvent extends ExtendableEvent {
  readonly data: { text(): string } | null;
}

export interface NotificationEvent extends ExtendableEvent {
  readonly notification: Notification;
}

export interface PushSubscriptionChangeEvent extends ExtendableEvent {
  readonly oldSubscription: PushSubscription | null;
  readonly newSubscription: PushSubscription | null;
}

export interface WindowClient {
  readonly url: string;
  focus(): Promise<WindowClient>;
  navigate(url: string): Promise<WindowClient | null>;
}

export interface ServiceWorkerScope {
  __WB_MANIFEST: Array<PrecacheEntry | string>;
  readonly location: Location;
  readonly registration: ServiceWorkerRegistration;
  readonly clients: {
    matchAll(options: {
      type: "window";
      includeUncontrolled: boolean;
    }): Promise<readonly WindowClient[]>;
    openWindow(url: string): Promise<WindowClient | null>;
  };
  skipWaiting(): Promise<void>;
  addEventListener(type: "push", listener: (event: PushEvent) => void): void;
  addEventListener(
    type: "notificationclick",
    listener: (event: NotificationEvent) => void,
  ): void;
  addEventListener(
    type: "pushsubscriptionchange",
    listener: (event: PushSubscriptionChangeEvent) => void,
  ): void;
}
