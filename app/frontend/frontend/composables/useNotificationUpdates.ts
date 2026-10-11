import { useQueryClient } from "@tanstack/vue-query";
import {
  getFriendsPendingCountQueryKey,
  getNotificationsQueryKey,
  getNotificationsUnreadCountQueryKey,
  type Notification,
  type Notifications,
} from "@/services/fyApi";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

// No subscription of its own: `useUpdates` already listens on
// UserNotificationsChannel for the toast and calls in here, so the center and
// the badge refresh off that one handler.
export const useNotificationInvalidation = () => {
  const queryClient = useQueryClient();

  const invalidateUnreadCount = () => {
    void queryClient.invalidateQueries({
      queryKey: getNotificationsUnreadCountQueryKey(),
    });
  };

  // A friend request arrives as a notification and nothing else, so the badge
  // that counts the waiting ones refreshes off the same handler rather than
  // waiting out its interval.
  const invalidatePendingFriendRequests = () => {
    void queryClient.invalidateQueries({
      queryKey: getFriendsPendingCountQueryKey(),
    });
  };

  // A claim is opened, completed or cancelled by another fleet, and the
  // notification is the only word of it a holder's open page gets.
  const invalidateFidClaims = (notification: Notification) => {
    if (!notification.notificationType?.startsWith("fleet_fid_claim")) return;

    void queryClient.invalidateQueries({
      predicate: (query) =>
        query.queryKey[0] === "fleets" && query.queryKey[2] === "fid-claim",
    });
  };

  const invalidate = () => {
    void queryClient.invalidateQueries({
      queryKey: getNotificationsQueryKey(),
    });
    invalidateUnreadCount();
    invalidatePendingFriendRequests();
  };

  // Swaps one row for the version the server just returned. Refetching would
  // reorder the list - the query sorts unread first - and pull the notification
  // the reader has open out from under them, so marking one read patches the
  // cache it came from instead.
  const patchCached = (notification: Notification) => {
    queryClient.setQueriesData<Notifications>(
      { queryKey: getNotificationsQueryKey() },
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

  return {
    invalidate,
    invalidateUnreadCount,
    invalidatePendingFriendRequests,
    invalidateFidClaims,
    patchCached,
  };
};

const TOAST_TAG_PREFIX = "notification:";

export const notificationToastTag = (id: string) => `${TOAST_TAG_PREFIX}${id}`;

// Takes down the toast that announced a notification once the notification has
// been read, archived, deleted or withdrawn. Without ids, every one goes.
export const useNotificationToasts = () => {
  const { dismissTagged } = useAppNotifications();

  const dismiss = (ids?: string[]) => {
    if (!ids) {
      dismissTagged((tag) => tag.startsWith(TOAST_TAG_PREFIX));

      return;
    }

    const tags = ids.map(notificationToastTag);

    dismissTagged((tag) => tags.includes(tag));
  };

  return { dismiss };
};
