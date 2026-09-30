import {
  createPushSubscription,
  destroyPushSubscription,
  type PushSubscriptionInput,
} from "@/services/fyApi";

export enum WebPushStatusEnum {
  UNSUPPORTED = "unsupported",
  DENIED = "denied",
  OFF = "off",
  ON = "on",
}

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
  const supported = ref(pushSupported());

  const permission = ref<NotificationPermission>(
    supported.value ? window.Notification.permission : "default",
  );

  // The server's row for this browser, which is how the device list tells
  // this device apart from the others.
  const subscriptionId = ref<string>();

  const busy = ref(false);

  // Not `serviceWorker.ready`: that never settles where no worker is
  // registered, which is every dev server.
  const registration = async () => {
    // eslint-disable-next-line compat/compat -- only reached once pushSupported() saw it
    const found = await navigator.serviceWorker.getRegistration("/");

    if (!found) {
      supported.value = false;
    }

    return found;
  };

  const save = async (subscription: PushSubscription) => {
    const row = await createPushSubscription(toInput(subscription));

    subscriptionId.value = row.id;
  };

  // A browser that subscribed on an earlier visit announces itself again: the
  // answer names its row, and a row the server pruned in the meantime comes
  // back.
  const refresh = async () => {
    if (!supported.value) return;

    const subscription = await (
      await registration()
    )?.pushManager.getSubscription();

    if (subscription && permission.value === "granted") {
      await save(subscription);
    } else {
      subscriptionId.value = undefined;
    }
  };

  // Only ever from a click: a prompt nobody asked for is the quickest way to
  // a permanent "denied", which nothing on the page can undo.
  const enable = async () => {
    if (!supported.value || busy.value) return false;

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

      await save(subscription);

      return true;
    } finally {
      busy.value = false;
    }
  };

  const disable = async () => {
    if (!supported.value || busy.value) return;

    busy.value = true;

    try {
      const subscription = await (
        await registration()
      )?.pushManager.getSubscription();

      if (subscriptionId.value) {
        await destroyPushSubscription(subscriptionId.value);
      }

      await subscription?.unsubscribe();

      subscriptionId.value = undefined;
    } finally {
      busy.value = false;
    }
  };

  const status = computed(() => {
    if (!supported.value) return WebPushStatusEnum.UNSUPPORTED;
    if (permission.value === "denied") return WebPushStatusEnum.DENIED;

    return subscriptionId.value ? WebPushStatusEnum.ON : WebPushStatusEnum.OFF;
  });

  return { status, busy, subscriptionId, refresh, enable, disable };
};
