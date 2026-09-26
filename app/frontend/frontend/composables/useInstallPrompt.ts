import { useComlink } from "@/shared/composables/useComlink";
import { useNotificationsStore } from "@/shared/stores/notifications";
import { MessageTypesEnum } from "@/shared/components/AppNotifications/types";
import { v4 as uuidv4 } from "uuid";

type InstallOutcome = "accepted" | "dismissed";

interface BeforeInstallPromptEvent extends Event {
  prompt: () => Promise<void>;
  userChoice: Promise<{ outcome: InstallOutcome }>;
}

export type InstallPromptContext = "eventSignup";

const STORAGE_KEY = "fy.install-prompt";
const COOLDOWN_DAYS = 90;
// Measured from the first sighting rather than flagged per tab: sessionStorage
// is per tab, so a second tab opened on the first visit would count as a return.
const FIRST_VISIT_DAYS = 1;

interface StoredState {
  firstSeenAt?: string;
  lastOfferedAt?: string;
}

const readState = (): StoredState => {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? (JSON.parse(raw) as StoredState) : {};
  } catch {
    return {};
  }
};

const writeState = (patch: StoredState) => {
  try {
    localStorage.setItem(
      STORAGE_KEY,
      JSON.stringify({ ...readState(), ...patch }),
    );
  } catch {
    // ignore storage failures
  }
};

const daysSince = (iso?: string): number | null => {
  if (!iso) return null;
  const parsed = Date.parse(iso);
  if (Number.isNaN(parsed)) return null;
  return (Date.now() - parsed) / 86_400_000;
};

const detectStandalone = (): boolean => {
  try {
    return (
      window.matchMedia("(display-mode: standalone)").matches ||
      (navigator as Navigator & { standalone?: boolean }).standalone === true
    );
  } catch {
    return false;
  }
};

// iPadOS reports itself as a Mac, so a touch screen is what gives it away.
// Safari and the other iOS browsers can add to the Home Screen; the in-app
// browsers of Discord, Instagram and co. cannot, and their user agents drop the
// Safari token or name the app.
const detectIos = (): boolean => {
  try {
    const userAgent = navigator.userAgent;
    const isAppleMobile =
      /iPad|iPhone|iPod/.test(userAgent) ||
      (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1);

    return (
      isAppleMobile &&
      /Safari\//.test(userAgent) &&
      !/FBAN|FBAV|Instagram|Line\/|Discord|Slack|Twitter/i.test(userAgent)
    );
  } catch {
    return false;
  }
};

const isAutomatedBrowser = (): boolean => {
  try {
    return navigator.webdriver === true;
  } catch {
    return false;
  }
};

const deferredPrompt = shallowRef<BeforeInstallPromptEvent | null>(null);
const standalone = ref(false);
const ios = ref(false);

let captured = false;

// The browser fires `beforeinstallprompt` once, early, and never again for the
// page -- a listener registered when a component mounts has already missed it.
// Holding on to it also keeps Chrome's own mini-infobar from showing on a first
// visit, which leaves the timing to us.
export const captureInstallPrompt = () => {
  if (captured) return;
  captured = true;

  standalone.value = detectStandalone();
  ios.value = detectIos();

  if (!readState().firstSeenAt) {
    writeState({ firstSeenAt: new Date().toISOString() });
  }

  window.addEventListener("beforeinstallprompt", (event) => {
    event.preventDefault();
    deferredPrompt.value = event as BeforeInstallPromptEvent;
  });

  // Chrome stops firing `beforeinstallprompt` while the app is installed and
  // starts again after an uninstall, so nothing about the install is stored.
  window.addEventListener("appinstalled", () => {
    deferredPrompt.value = null;
  });

  try {
    window
      .matchMedia("(display-mode: standalone)")
      .addEventListener("change", (event) => {
        standalone.value = event.matches;
      });
  } catch {
    // matchMedia listeners are missing in old Safari
  }
};

export const useInstallPrompt = () => {
  const comlink = useComlink();
  const notificationsStore = useNotificationsStore();

  const isStandalone = readonly(standalone);

  const isIos = readonly(ios);

  // iOS has no prompt API; every browser there installs through the share
  // sheet, so it can always be explained instead.
  const canInstall = computed(
    () => !standalone.value && (!!deferredPrompt.value || ios.value),
  );

  const openIosInstructions = () => {
    comlink.emit("open-modal", {
      component: () =>
        import("@/frontend/components/InstallApp/IosModal/index.vue"),
    });
  };

  const install = async (): Promise<InstallOutcome | undefined> => {
    const event = deferredPrompt.value;

    if (event) {
      // A prompt can only be shown once; Chrome fires a fresh event if the
      // app is still installable afterwards.
      deferredPrompt.value = null;

      try {
        await event.prompt();
      } catch {
        // Refused outside a user gesture; the event is still good for a click.
        deferredPrompt.value = event;
        return undefined;
      }

      const { outcome } = await event.userChoice;

      if (outcome === "dismissed") {
        writeState({ lastOfferedAt: new Date().toISOString() });
      }

      return outcome;
    }

    if (ios.value) {
      openIosInstructions();
    }

    return undefined;
  };

  const canOffer = (): boolean => {
    if (!canInstall.value) return false;
    if (isAutomatedBrowser()) return false;
    const state = readState();

    const sinceFirstSeen = daysSince(state.firstSeenAt);
    if (sinceFirstSeen === null || sinceFirstSeen < FIRST_VISIT_DAYS) {
      return false;
    }

    const since = daysSince(state.lastOfferedAt);
    return since === null || since > COOLDOWN_DAYS;
  };

  const dispatchOffer = (context: InstallPromptContext) => {
    const notificationId = uuidv4();

    notificationsStore.addMessage({
      id: notificationId,
      type: MessageTypesEnum.INFO,
      visible: true,
      persist: true,
      timeout: false,
      component: () =>
        import("@/frontend/components/InstallApp/Hint/index.vue"),
      componentProps: {
        context,
        notificationId,
      },
    });
  };

  // Shown or not, an offer counts against the cooldown: closing the message
  // is as much of an answer as the "not now" button.
  const offer = (context: InstallPromptContext) => {
    if (!canOffer()) return false;

    writeState({ lastOfferedAt: new Date().toISOString() });
    dispatchOffer(context);

    return true;
  };

  return {
    canInstall,
    isIos,
    isStandalone,
    install,
    openIosInstructions,
    canOffer,
    offer,
    forceOffer: dispatchOffer,
  };
};
