import { isAxiosError } from "axios";
import {
  createPushSubscription,
  destroyPushSubscription,
  touchPushSubscription,
  type PushSubscriptionInput,
} from "@/services/fyApi";

export enum WebPushStatusEnum {
  UNSUPPORTED = "unsupported",
  DENIED = "denied",
  FAILED = "failed",
  OFF = "off",
  ON = "on",
}

// What this browser last subscribed as, so a visit can tell a device removed
// on purpose -- stays off -- from one whose renewal never reached the server,
// which is saved again.
type StoredSubscription = {
  id: string;
  endpoint: string;
  userId: string;
  p256dh?: string;
  auth?: string;
};

const STORAGE_KEY = "fy.push-subscription";

// Registration runs after DOMContentLoaded, so a page opened straight away can
// ask before it has finished.
const REGISTRATION_WAIT_MS = 10_000;

const readStored = (): StoredSubscription | undefined => {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    const parsed: unknown = raw ? JSON.parse(raw) : undefined;

    return parsed && typeof parsed === "object" && "id" in parsed
      ? (parsed as StoredSubscription)
      : undefined;
  } catch {
    return undefined;
  }
};

const writeStored = (stored?: StoredSubscription) => {
  try {
    if (stored) {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(stored));
    } else {
      localStorage.removeItem(STORAGE_KEY);
    }
  } catch {
    // ignore storage failures
  }
};

// The VAPID key is base64url; the Push API wants its raw bytes.
export const applicationServerKey = (
  base64url: string,
): Uint8Array<ArrayBuffer> => {
  const base64 = base64url
    .replace(/-/g, "+")
    .replace(/_/g, "/")
    .padEnd(Math.ceil(base64url.length / 4) * 4, "=");

  return Uint8Array.from(atob(base64), (char) => char.charCodeAt(0));
};

// No key means the server cannot send (only production holds one), and a
// browser without these APIs cannot receive -- iOS Safari only has them in a
// web app added to the Home Screen.
const pushSupported = () =>
  typeof window !== "undefined" &&
  "serviceWorker" in navigator &&
  "PushManager" in window &&
  "Notification" in window &&
  !!window.VAPID_PUBLIC_KEY;

const toInput = (subscription: PushSubscription): PushSubscriptionInput => {
  const json = subscription.toJSON();

  return {
    endpoint: subscription.endpoint,
    expirationTime: json.expirationTime ?? null,
    keys: { p256dh: json.keys?.p256dh ?? "", auth: json.keys?.auth ?? "" },
  };
};

export const useWebPush = () => {
  const supported = pushSupported();

  const permission = ref<NotificationPermission>(
    supported ? window.Notification.permission : "default",
  );

  // Looked up again on every call: missing now can mean not registered yet.
  const workerMissing = ref(false);

  const failed = ref(false);

  // The server's row for this browser, which is how the device list tells
  // this device apart from the others.
  const subscriptionId = ref<string>();

  const busy = ref(false);

  const registration = async () => {
    // eslint-disable-next-line compat/compat -- only reached once pushSupported() saw it
    const container = navigator.serviceWorker;

    const found =
      (await container.getRegistration("/")) ??
      (await Promise.race([
        container.ready,
        new Promise<undefined>((resolve) => {
          setTimeout(() => resolve(undefined), REGISTRATION_WAIT_MS);
        }),
      ]));

    workerMissing.value = !found;

    return found;
  };

  const save = async (subscription: PushSubscription, userId: string) => {
    const input = toInput(subscription);
    const row = await createPushSubscription(input);

    subscriptionId.value = row.id;
    writeStored({
      id: row.id,
      endpoint: input.endpoint,
      userId,
      p256dh: input.keys.p256dh,
      auth: input.keys.auth,
    });
  };

  // A browser can renew its keys and keep the endpoint; the server encrypts
  // with whatever keys it was last given.
  const renewed = (
    stored: StoredSubscription,
    subscription: PushSubscription,
  ) => {
    const input = toInput(subscription);

    return (
      stored.endpoint !== input.endpoint ||
      stored.p256dh !== input.keys.p256dh ||
      stored.auth !== input.keys.auth
    );
  };

  // Brings this browser and the server back in line, without ever turning
  // push on by itself:
  // - the row is still there: on, and touched, which is what tells the
  //   server this device is alive (it prunes rows nothing touched in half a
  //   year);
  // - the browser renewed its endpoint or keys but the server never heard
  //   (the worker had no session): the renewal is saved;
  // - this account removed the row, from here or another device: the browser
  //   unsubscribes too, and it stays off;
  // - it belongs to another account, or was never saved: off, left alone.
  //
  // A worker that has not turned up yet decides nothing: what is stored stays
  // for a later visit to reconcile.
  const refresh = async (userId: string) => {
    if (!supported) return;

    failed.value = false;

    try {
      const found = await registration();
      if (!found) return;

      const subscription = await found.pushManager.getSubscription();
      const stored = readStored();

      if (!subscription) {
        subscriptionId.value = undefined;
        writeStored(undefined);
        return;
      }

      if (
        permission.value !== "granted" ||
        !stored ||
        stored.userId !== userId
      ) {
        subscriptionId.value = undefined;
        return;
      }

      if (renewed(stored, subscription)) {
        await save(subscription, userId);
        return;
      }

      try {
        await touchPushSubscription(stored.id);
        subscriptionId.value = stored.id;
      } catch (error) {
        if (!isAxiosError(error) || error.response?.status !== 404) {
          throw error;
        }

        await subscription.unsubscribe();
        writeStored(undefined);
        subscriptionId.value = undefined;
      }
    } catch (error) {
      failed.value = true;
      throw error;
    }
  };

  // Only ever from a click: a prompt nobody asked for is the quickest way to
  // a permanent "denied", which nothing on the page can undo.
  const enable = async (userId: string) => {
    if (!supported || busy.value) return false;

    busy.value = true;

    try {
      permission.value = await window.Notification.requestPermission();

      if (permission.value !== "granted") return false;

      const found = await registration();

      if (!found) return false;

      const subscription =
        (await found.pushManager.getSubscription()) ??
        (await found.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: applicationServerKey(
            window.VAPID_PUBLIC_KEY as string,
          ),
        }));

      await save(subscription, userId);
      failed.value = false;

      return true;
    } finally {
      busy.value = false;
    }
  };

  // The browser first: if it refuses to let go, the server row stays and the
  // page keeps saying on, which is the truth.
  const disable = async () => {
    if (!supported || busy.value) return;

    busy.value = true;

    try {
      const subscription = await (
        await registration()
      )?.pushManager.getSubscription();

      if (subscription && !(await subscription.unsubscribe())) {
        throw new Error("the browser kept its push subscription");
      }

      const id = subscriptionId.value;
      subscriptionId.value = undefined;
      writeStored(undefined);

      if (id) await destroyPushSubscription(id);
    } finally {
      busy.value = false;
    }
  };

  const status = computed(() => {
    if (!supported || workerMissing.value) {
      return WebPushStatusEnum.UNSUPPORTED;
    }
    if (permission.value === "denied") return WebPushStatusEnum.DENIED;
    if (failed.value) return WebPushStatusEnum.FAILED;

    return subscriptionId.value ? WebPushStatusEnum.ON : WebPushStatusEnum.OFF;
  });

  return { status, busy, subscriptionId, refresh, enable, disable };
};
