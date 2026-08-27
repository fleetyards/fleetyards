import { useSessionStore } from "@/frontend/stores/session";
import { useAppStore } from "@/frontend/stores/app";
import { useHangarStore } from "@/frontend/stores/hangar";
import { useWishlistStore } from "@/frontend/stores/wishlist";
import { useI18n } from "@/shared/composables/useI18n";
import { useNotificationInvalidation } from "@/frontend/composables/useNotificationUpdates";
import {
  useSubscription,
  ChannelsEnum,
} from "@/shared/composables/useSubscription";
import { storeToRefs } from "pinia";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { MessageTypesEnum } from "@/shared/components/AppNotifications/types";
import { type AnnouncementMessage } from "@/services/fyCable/models/AnnouncementMessage";
import { AnnouncementTypeEnum } from "@/services/fyCable/models/AnnouncementTypeEnum";
import {
  type Model,
  type Notification,
  type Vehicle,
  useSyncRsiHangarStatus,
} from "@/services/fyApi";

const ANNOUNCEMENT_TYPES: Record<AnnouncementTypeEnum, MessageTypesEnum> = {
  [AnnouncementTypeEnum.SUCCESS]: MessageTypesEnum.SUCCESS,
  [AnnouncementTypeEnum.INFO]: MessageTypesEnum.INFO,
  [AnnouncementTypeEnum.WARNING]: MessageTypesEnum.WARNING,
  [AnnouncementTypeEnum.RESERVED_ALERT]: MessageTypesEnum.ALERT,
};

export const useUpdates = () => {
  const appStore = useAppStore();

  const updateAppVersion = (data: { version?: string; codename?: string }) => {
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
    channelName: ChannelsEnum.APP_VERSION_CHANNEL,
    received: updateAppVersion,
  });

  useSubscription({
    channelName: ChannelsEnum.ON_SALE_HANGAR_CHANNEL,
    received: notifyVehicleOnSale,
    enabled: isAuthenticated,
  });

  useSubscription({
    channelName: ChannelsEnum.ON_SALE_CHANNEL,
    received: notifyOnSale,
    enabled: isAuthenticated,
  });

  useSubscription({
    channelName: ChannelsEnum.HANGAR_CREATE_CHANNEL,
    received: addShipToHangar,
    enabled: isAuthenticated,
  });

  useSubscription({
    channelName: ChannelsEnum.HANGAR_DESTROY_CHANNEL,
    received: removeShipFromHangar,
    enabled: isAuthenticated,
  });

  useSubscription({
    channelName: ChannelsEnum.WISHLIST_CREATE_CHANNEL,
    received: addShipToWishlist,
    enabled: isAuthenticated,
  });

  useSubscription({
    channelName: ChannelsEnum.WISHLIST_DESTROY_CHANNEL,
    received: removeShipFromWishlist,
    enabled: isAuthenticated,
  });

  const handleHangarSyncUpdate = (message: { status: string }) => {
    if (message.status === "finished" || message.status === "failed") {
      hangarStore.syncRunning = false;
    }

    if (hangarStore.syncModalOpen) {
      return;
    }

    if (message.status === "finished") {
      displaySuccess({ text: t("messages.syncExtension.success") });
    } else if (message.status === "failed") {
      displayAlert({ text: t("messages.syncExtension.failure") });
    }
  };

  useSubscription({
    channelName: ChannelsEnum.HANGAR_SYNC_CHANNEL,
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
    channelName: ChannelsEnum.NOTIFICATIONS_CHANNEL,
    received: handleAnnouncement,
  });

  useSubscription({
    channelName: ChannelsEnum.USER_NOTIFICATIONS_CHANNEL,
    received: handleUserNotification,
  });
};
