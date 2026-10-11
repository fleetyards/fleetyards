import { useSessionStore } from "@/frontend/stores/session";
import { useAppStore } from "@/frontend/stores/app";
import { useHangarStore } from "@/frontend/stores/hangar";
import { useWishlistStore } from "@/frontend/stores/wishlist";
import { useI18n } from "@/shared/composables/useI18n";
import {
  notificationToastTag,
  useNotificationInvalidation,
  useNotificationToasts,
} from "@/frontend/composables/useNotificationUpdates";
import { useMovedFleetRedirect } from "@/frontend/composables/useMovedFleetRedirect";
import { useSubscription } from "@/shared/composables/useSubscription";
import { useComlink } from "@/shared/composables/useComlink";
import { syncOutcomeMessage } from "@/frontend/components/Hangar/SyncBtn/Result/status";
import { usePresenceUpdates } from "@/frontend/composables/usePresenceUpdates";
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
import {
  UserNotificationsChannel,
  type UserNotificationsData,
} from "@/services/fyCable/channels/UserNotificationsChannel";
import { WishlistCreateChannel } from "@/services/fyCable/channels/WishlistCreateChannel";
import { WishlistDestroyChannel } from "@/services/fyCable/channels/WishlistDestroyChannel";
import { type AnnouncementMessage } from "@/services/fyCable/models/AnnouncementMessage";
import { type AnnouncementTypeEnum } from "@/services/fyCable/models/AnnouncementTypeEnum";
import { type AppVersionMessage } from "@/services/fyCable/models/AppVersionMessage";
import { type Model } from "@/services/fyCable/models/Model";
import { type Vehicle } from "@/services/fyCable/models/Vehicle";
import { useSyncRsiHangarStatus } from "@/services/fyApi";
import { useHangarSync } from "@/frontend/composables/useHangarSync";

const ANNOUNCEMENT_TYPES: Record<AnnouncementTypeEnum, MessageTypesEnum> = {
  success: MessageTypesEnum.SUCCESS,
  info: MessageTypesEnum.INFO,
  warning: MessageTypesEnum.WARNING,
  alert: MessageTypesEnum.ALERT,
};

export const useUpdates = () => {
  // Mounted here rather than on the surfaces that draw a dot: the subscription
  // is also this client's own heartbeat, so it has to run wherever the app is
  // open.
  usePresenceUpdates();

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

  const comlink = useComlink();

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

  const { invalidate: invalidateNotifications, invalidateFidClaims } =
    useNotificationInvalidation();

  const { dismiss: dismissNotificationToasts } = useNotificationToasts();

  const followMovedFleet = useMovedFleetRedirect(useRouter(), useRoute());

  // A notification is a record, so its fields have to be mapped onto the toast.
  // The toast is also the way into the center it was just filed in — unlike the
  // admin's it keeps its timeout, because it interrupts browsing rather than
  // reporting an operational failure that must not be missed.
  //
  // Withdrawn ones were taken down with what they were about; the refetch drops
  // them from the center and the badge, and a toast still up for one goes too.
  const handleUserNotification = (message: UserNotificationsData) => {
    invalidateNotifications();

    if ("withdrawnIds" in message) {
      dismissNotificationToasts(message.withdrawnIds);

      return;
    }

    invalidateFidClaims(message);
    void followMovedFleet(message);

    displayMessage({
      text: message.title,
      icon: message.icon,
      to: { name: "notifications" },
      tag: notificationToastTag(message.id),
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

  // A run this tab started reports on itself, wherever the user is by now.
  const hangarSync = useHangarSync();

  const handleHangarSyncUpdate = (message: HangarSyncData) => {
    const finished = message.status === "finished";
    const failed = message.status === "failed";

    if (finished || failed || message.status === "cancelled") {
      hangarStore.syncRunning = false;
    }

    if (hangarSync.receive(message)) {
      return;
    }

    if (finished) {
      comlink.emit("hangar-sync-finished");

      const { synced, key } = syncOutcomeMessage(
        message.result.outcome,
        message.result.incomplete,
      );
      (synced ? displaySuccess : displayInfo)({ text: t(key) });
    } else if (failed) {
      displayAlert({ text: t("messages.syncExtension.failure") });
    }
  };

  useSubscription({
    channel: HangarSyncChannel,
    received: handleHangarSyncUpdate,
    enabled: isAuthenticated,
  });

  // The cable message can be missed across a reconnect, so a run waiting on
  // its result also asks for it.
  const { data: syncStatus, dataUpdatedAt: syncStatusUpdatedAt } =
    useSyncRsiHangarStatus({
      query: {
        enabled: isAuthenticated,
        refetchInterval: computed(() =>
          hangarSync.polling.value ? 5000 : false,
        ),
      },
    });

  // On every answer, not only a changed one: a re-sync of an unchanged hangar
  // answers exactly what the previous run did, and structural sharing keeps
  // the same data for it.
  watch(
    syncStatusUpdatedAt,
    () => {
      const status = syncStatus.value;

      if (status) {
        hangarStore.syncRunning = status.active;
        hangarSync.receiveStatus(status);
      }
    },
    { immediate: true },
  );

  // Anything still submitted or shown after a sign-out would land on an
  // account that is no longer here.
  watch(isAuthenticated, (authenticated) => {
    if (!authenticated) hangarSync.reset(true);
  });

  useSubscription({
    channel: NotificationsChannel,
    received: handleAnnouncement,
  });

  useSubscription({
    channel: UserNotificationsChannel,
    received: handleUserNotification,
  });
};
