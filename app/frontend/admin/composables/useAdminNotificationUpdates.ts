import { type Ref } from "vue";
import { useQueryClient } from "@tanstack/vue-query";
import {
  useSubscription,
  type ConnectEvent,
} from "@/shared/composables/useSubscription";
import {
  AdminNotificationsChannel,
  type AdminNotificationsData,
} from "@/services/fyCableAdmin/channels/AdminNotificationsChannel";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  getAdminNotificationsQueryKey,
  getAdminNotificationsUnreadCountQueryKey,
  type AdminNotification,
  type AdminNotifications,
  AdminNotificationSeverityEnum,
} from "@/services/fyAdminApi";

export const useAdminNotificationInvalidation = () => {
  const queryClient = useQueryClient();

  const invalidateUnreadCount = () => {
    void queryClient.invalidateQueries({
      queryKey: getAdminNotificationsUnreadCountQueryKey(),
    });
  };

  const invalidate = () => {
    void queryClient.invalidateQueries({
      queryKey: getAdminNotificationsQueryKey(),
    });
    invalidateUnreadCount();
  };

  // Swaps one row for the version the server just returned. Refetching would
  // reorder the list - the query sorts unread first - and pull the notification
  // the reader has open out from under them, so marking one read patches the
  // cache it came from instead.
  const patchCached = (notification: AdminNotification) => {
    queryClient.setQueriesData<AdminNotifications>(
      { queryKey: getAdminNotificationsQueryKey() },
      (data) => {
        // The list key is also a prefix of the unread-count key, whose payload
        // carries no items.
        if (!data?.items) {
          return data;
        }

        return {
          ...data,
          items: data.items.map((item) =>
            item.id === notification.id ? notification : item,
          ),
        };
      },
    );
  };

  return { invalidate, invalidateUnreadCount, patchCached };
};

const TOAST_TAG_PREFIX = "admin-notification:";

const toastTag = (id: string) => `${TOAST_TAG_PREFIX}${id}`;

// A toast announces an unread notification, so reading, archiving or deleting
// it on the notifications page takes the toast with it.
export const useAdminNotificationToasts = () => {
  const { dismissTagged } = useAppNotifications();

  const dismiss = (ids: string[]) => {
    const tags = ids.map(toastTag);

    dismissTagged((tag) => tags.includes(tag));
  };

  const dismissAll = () => {
    dismissTagged((tag) => tag.startsWith(TOAST_TAG_PREFIX));
  };

  return { dismiss, dismissAll };
};

// Subscribe once, from the navigation: the invalidation is global, so a page
// listing notifications refreshes off this subscription too, and a second one
// would only double every toast.
export const useAdminNotificationUpdates = (enabled: Ref<boolean>) => {
  const { invalidate } = useAdminNotificationInvalidation();

  const { displayInfo, displayWarning, displayAlert } = useAppNotifications();

  const announce = (notification: AdminNotificationsData) => {
    // The notification center keeps what a toast only announces, so the toast
    // can go on its own; clicking it lands in the center.
    const message = {
      text: notification.title,
      timeout: 10_000,
      to: { name: "admin-notifications" },
      tag: toastTag(notification.id),
    };

    switch (notification.severity) {
      case AdminNotificationSeverityEnum.ERROR:
        displayAlert(message);
        break;
      case AdminNotificationSeverityEnum.WARNING:
        displayWarning(message);
        break;
      default:
        displayInfo(message);
    }
  };

  const received = (notification: AdminNotificationsData) => {
    invalidate();

    announce(notification);
  };

  // Whatever was broadcast while the socket was down is gone - the channel has
  // no replay - so a reconnect has to resync rather than carry on. Without it a
  // notification that arrives while the tab sits in the background is missing
  // from the list until something else refetches it, and the unread count, on
  // its own interval, is the only sign it ever happened. Not on the first
  // connect: the queries have only just loaded.
  const connected = ({ reconnect }: ConnectEvent) => {
    if (reconnect) {
      invalidate();
    }
  };

  useSubscription({
    channel: AdminNotificationsChannel,
    received,
    connected,
    enabled,
  });

  return { invalidate };
};
