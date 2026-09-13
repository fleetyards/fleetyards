import { useQueryClient } from "@tanstack/vue-query";
import {
  getFriendsPendingCountQueryKey,
  getNotificationsQueryKey,
  getNotificationsUnreadCountQueryKey,
  type Notification,
  type Notifications,
} from "@/services/fyApi";

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
    patchCached,
  };
};
