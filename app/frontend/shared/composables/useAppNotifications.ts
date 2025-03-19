import { useNotificationsStore } from "@/shared/stores/notifications";
import { useI18n } from "@/shared/composables/useI18n";
import {
  MessageTypesEnum,
  type AppNotification,
} from "@/shared/components/AppNotifications/types";
import { v4 as uuidv4 } from "uuid";
import { useComlink } from "@/shared/composables/useComlink";
import { type AppConfirmOptions } from "@/shared/components/AppConfirm/types";

export const useAppNotifications = () => {
  const { t } = useI18n();

  const notificationsStore = useNotificationsStore();

  const notifyPermissionGranted = () =>
    "Notification" in window && window.Notification.permission === "granted";

  const requestBrowserPermission = () => {
    if (!("Notification" in window) || notifyPermissionGranted()) {
      return;
    }

    window.Notification.requestPermission((permission) => {
      if (permission === "granted") {
        displayNativeNotification(t("messages.notification.granted"));
      }
    });
  };

  const displayDesktopNotification = (message: string) => {
    const notification = new window.Notification(message, {
      // eslint-disable-next-line global-require
      icon: `${window.FRONTEND_ENDPOINT}${require("@/images/favicon.png")}`,
    });

    return notification;
  };

  const displayNativeNotification = (message: string) => {
    if ("serviceWorker" in navigator) {
      navigator.serviceWorker.ready.then(
        (registration) => {
          if (!registration.showNotification) {
            return;
          }

          registration.showNotification(message, {
            icon: `${window.FRONTEND_ENDPOINT}/images/favicon.png`,
            // @ts-ignore vibrate is allowed here
            vibrate: [200, 100, 200, 100, 200, 100, 200],
          });
        },
        () => {
          displayDesktopNotification(message);
        },
      );
    } else {
      displayDesktopNotification(message);
    }
  };

  const displayMessage = (notification: Partial<AppNotification>) => {
    const id = uuidv4();

    const text = notification.text;

    if (!text && !notification.component) {
      return;
    }

    const persist = notification.persist || false;

    const timeout =
      notification.timeout != undefined ? notification.timeout : 3000;

    notificationsStore.addMessage({
      type: MessageTypesEnum.INFO,
      visible: true,
      ...notification,
      id,
      text,
      timeout,
      persist,
    });

    if (
      document.hidden &&
      notifyPermissionGranted() &&
      notification.background &&
      text
    ) {
      displayNativeNotification(text.replace(/(<([^>]+)>)/gi, ""));
    }
  };

  const displayAlert = (notification: Partial<AppNotification>) => {
    displayMessage({
      ...notification,
      type: MessageTypesEnum.ALERT,
    });
  };

  const displaySuccess = (notification: Partial<AppNotification>) => {
    displayMessage({
      ...notification,
      type: MessageTypesEnum.SUCCESS,
    });
  };

  const displayInfo = (notification: Partial<AppNotification>) => {
    displayMessage({
      ...notification,
      type: MessageTypesEnum.INFO,
    });
  };

  const displayWarning = (notification: Partial<AppNotification>) => {
    displayMessage({
      ...notification,
      type: MessageTypesEnum.WARNING,
    });
  };

  const comlink = useComlink();

  const displayConfirm = (options: AppConfirmOptions) => {
    comlink.emit("show-confirm", options);
  };

  return {
    displayMessage,
    displayAlert,
    displaySuccess,
    displayInfo,
    displayWarning,
    displayConfirm,
    displayNativeNotification,
    requestBrowserPermission,
  };
};
