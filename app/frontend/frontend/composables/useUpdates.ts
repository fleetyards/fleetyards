import { useSessionStore } from "@/frontend/stores/session";
import { useAppStore } from "@/frontend/stores/app";
import { useHangarStore } from "@/frontend/stores/hangar";
import { useWishlistStore } from "@/frontend/stores/wishlist";
import { useI18n } from "@/shared/composables/useI18n";
import { useNotificationInvalidation } from "@/frontend/composables/useNotificationUpdates";
import { useSubscription } from "@/shared/composables/useSubscription";
import { storeToRefs } from "pinia";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { MessageTypesEnum } from "@/shared/components/AppNotifications/types";
import { AppVersionChannel } from "@/services/fyCable/channels/AppVersionChannel";
import { HangarCreateChannel } from "@/services/fyCable/channels/HangarCreateChannel";
import { HangarDestroyChannel } from "@/services/fyCable/channels/HangarDestroyChannel";
import {
  HangarSyncChannel,
  type HangarSyncData,
} from "@/services/fyCable/channels/HangarSyncChannel";
import { NotificationsChannel } from "@/services/fyCable/channels/NotificationsChannel";
import { OnSaleChannel } from "@/services/fyCable/channels/OnSaleChannel";
import { OnSaleHangarChannel } from "@/services/fyCable/channels/OnSaleHangarChannel";
import { UserNotificationsChannel } from "@/services/fyCable/channels/UserNotificationsChannel";
import { WishlistCreateChannel } from "@/services/fyCable/channels/WishlistCreateChannel";
import { WishlistDestroyChannel } from "@/services/fyCable/channels/WishlistDestroyChannel";
import { type AnnouncementMessage } from "@/services/fyCable/models/AnnouncementMessage";
import { type AnnouncementTypeEnum } from "@/services/fyCable/models/AnnouncementTypeEnum";
import { type AppVersionMessage } from "@/services/fyCable/models/AppVersionMessage";
import { type Model } from "@/services/fyCable/models/Model";
import { type Notification } from "@/services/fyCable/models/Notification";
import { type Vehicle } from "@/services/fyCable/models/Vehicle";
import { useSyncRsiHangarStatus } from "@/services/fyApi";

const ANNOUNCEMENT_TYPES: Record<AnnouncementTypeEnum, MessageTypesEnum> = {
  success: MessageTypesEnum.SUCCESS,
  info: MessageTypesEnum.INFO,
  warning: MessageTypesEnum.WARNING,
  alert: MessageTypesEnum.ALERT,
};

export const useUpdates = () => {
  const appStore = useAppStore();

  const updateAppVersion = (data: AppVersionMessage) => {
    appStore.updateVersion(data);
  };

  const hangarStore = useHangarStore();

  const addShipToHangar = (vehicle: Vehicle) => {
    if (!vehicle.model) {
      return;
    }

    hangarStore.add(vehicle.model.slug);
  };

  const removeShipFromHangar = (vehicle: Vehicle) => {
    if (!vehicle.model) {
      return;
    }

    hangarStore.remove(vehicle.model.slug);
  };

  const wishlistStore = useWishlistStore();

  const addShipToWishlist = (vehicle: Vehicle) => {
    if (!vehicle.model) {
      return;
    }

    wishlistStore.add(vehicle.model.slug);
  };

  const removeShipFromWishlist = (vehicle: Vehicle) => {
    if (!vehicle.model) {
      return;
    }

    wishlistStore.remove(vehicle.model.slug);
  };

  const { t } = useI18n();

  const { displayMessage, displayInfo, displaySuccess, displayAlert } =
    useAppNotifications();

  const sessionStore = useSessionStore();

  const { currentUser, isAuthenticated } = storeToRefs(sessionStore);

  const notifyVehicleOnSale = (vehicle: Vehicle) => {
    if (!currentUser?.value?.saleNotify) {
      return;
    }

    if (!vehicle.saleNotify) {
      return;
    }

    displayInfo({
      text: t("messages.model.onSale", {
        model: vehicle.model?.name,
      }),
      icon: vehicle.model?.media?.storeImage?.smallUrl,
    });
  };

  const notifyOnSale = (model: Model) => {
    if (!currentUser?.value?.saleNotify) {
      return;
    }

    displayInfo({
      text: t("messages.model.onSale", { model: model.name }),
      icon: model.media?.storeImage?.smallUrl,
    });
  };

  // A server-wide announcement is already shaped like the toast it becomes —
  // it has no counterpart resource in the REST API, so nothing is derived here.
  // The map is exhaustive over the generated enum, so a severity added to the
  // cable contract fails to compile here rather than arriving unhandled.
  const handleAnnouncement = (announcement: AnnouncementMessage) => {
    displayMessage({
      text: announcement.text,
      type: announcement.type && ANNOUNCEMENT_TYPES[announcement.type],
      persist: announcement.persist,
      timeout: announcement.timeout,
      background: announcement.background,
    });
  };

  const { invalidate: invalidateNotifications } = useNotificationInvalidation();

  // A notification is a record, so its fields have to be mapped onto the toast.
  // The toast is also the way into the center it was just filed in — unlike the
  // admin's it keeps its timeout, because it interrupts browsing rather than
  // reporting an operational failure that must not be missed.
  const handleUserNotification = (notification: Notification) => {
    invalidateNotifications();

    displayMessage({
      text: notification.title,
      icon: notification.icon,
      to: { name: "notifications" },
    });
  };

  useSubscription({
    channel: AppVersionChannel,
    received: updateAppVersion,
  });

  useSubscription({
    channel: OnSaleHangarChannel,
    received: notifyVehicleOnSale,
    enabled: isAuthenticated,
  });

  useSubscription({
    channel: OnSaleChannel,
    received: notifyOnSale,
    enabled: isAuthenticated,
  });

  useSubscription({
    channel: HangarCreateChannel,
    received: addShipToHangar,
    enabled: isAuthenticated,
  });

  useSubscription({
    channel: HangarDestroyChannel,
    received: removeShipFromHangar,
    enabled: isAuthenticated,
  });

  useSubscription({
    channel: WishlistCreateChannel,
    received: addShipToWishlist,
    enabled: isAuthenticated,
  });

  useSubscription({
    channel: WishlistDestroyChannel,
    received: removeShipFromWishlist,
    enabled: isAuthenticated,
  });

  const handleHangarSyncUpdate = (message: HangarSyncData) => {
    const finished = message.status === "finished";
    const failed = message.status === "failed";

    if (finished || failed) {
      hangarStore.syncRunning = false;
    }

    if (hangarStore.syncModalOpen) {
      return;
    }

    if (finished) {
      displaySuccess({ text: t("messages.syncExtension.success") });
    } else if (failed) {
      displayAlert({ text: t("messages.syncExtension.failure") });
    }
  };

  useSubscription({
    channel: HangarSyncChannel,
    received: handleHangarSyncUpdate,
    enabled: isAuthenticated,
  });

  const { data: syncStatus } = useSyncRsiHangarStatus({
    query: {
      enabled: isAuthenticated,
    },
  });

  watch(
    () => syncStatus.value,
    (status) => {
      if (status) {
        hangarStore.syncRunning = status.active;
      }
    },
    { immediate: true },
  );

  useSubscription({
    channel: NotificationsChannel,
    received: handleAnnouncement,
  });

  useSubscription({
    channel: UserNotificationsChannel,
    received: handleUserNotification,
  });
};
