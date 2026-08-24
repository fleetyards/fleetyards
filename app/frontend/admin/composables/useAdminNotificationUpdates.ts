import { type Ref } from "vue";
import { useQueryClient } from "@tanstack/vue-query";
import {
  useSubscription,
  ChannelsEnum,
} from "@/shared/composables/useSubscription";
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

// Subscribe once, from the navigation: the invalidation is global, so a page
// listing notifications refreshes off this subscription too, and a second one
// would only double every toast.
export const useAdminNotificationUpdates = (enabled: Ref<boolean>) => {
  const { invalidate } = useAdminNotificationInvalidation();

  const { displayInfo, displayWarning, displayAlert } = useAppNotifications();

  const announce = (notification: AdminNotification) => {
    // No timeout: a report that arrives while nobody is looking is the whole
    // point of the notification center, so the toast waits to be clicked away,
    // and that click lands in the center rather than only dismissing it.
    const message = {
      text: notification.title,
      timeout: false as const,
      to: { name: "admin-notifications" },
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

  const received = (data: string) => {
    invalidate();

    announce(JSON.parse(data) as AdminNotification);
  };

  useSubscription({
    channelName: ChannelsEnum.ADMIN_NOTIFICATIONS,
    received,
    enabled,
  });

  return { invalidate };
};
