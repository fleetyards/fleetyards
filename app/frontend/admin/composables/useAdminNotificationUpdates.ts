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
import { useNotificationsStore } from "@/shared/stores/notifications";
import {
  adminNotifications,
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

// The API's per-page ceiling.
const RESYNC_PAGE_SIZE = 100;

const chunk = <T>(items: T[], size: number) =>
  Array.from({ length: Math.ceil(items.length / size) }, (_, index) =>
    items.slice(index * size, (index + 1) * size),
  );

const toastTag = (id: string) => `${TOAST_TAG_PREFIX}${id}`;

export const useAdminNotificationToasts = () => {
  const { dismissTagged } = useAppNotifications();

  const notificationsStore = useNotificationsStore();

  const dismiss = (ids: string[]) => {
    const tags = ids.map(toastTag);

    dismissTagged((tag) => tags.includes(tag));
  };

  const openIds = () =>
    notificationsStore.messages
      .filter(
        ({ visible, tag }) => visible && tag?.startsWith(TOAST_TAG_PREFIX),
      )
      .map(({ tag }) => tag!.slice(TOAST_TAG_PREFIX.length));

  // The settled broadcast is the usual way a toast goes, but a socket that is
  // down drops it like any other, so the toasts still up can also ask whether
  // their notification is still unread.
  const resync = async () => {
    const ids = openIds();

    try {
      const pages = await Promise.all(
        chunk(ids, RESYNC_PAGE_SIZE).map((page) =>
          adminNotifications({
            perPage: String(page.length),
            q: { idIn: page, readAtNull: true },
          }),
        ),
      );

      const unread = new Set(
        pages.flatMap(({ items }) => items.map(({ id }) => id)),
      );

      dismiss(ids.filter((id) => !unread.has(id)));
    } catch {
      // The toasts stay up; the next settle or resync takes them down.
    }
  };

  return { dismiss, resync };
};

// Subscribe once, from the navigation: the invalidation is global, so a page
// listing notifications refreshes off this subscription too, and a second one
// would only double every toast.
export const useAdminNotificationUpdates = (enabled: Ref<boolean>) => {
  const { invalidate, invalidateUnreadCount } =
    useAdminNotificationInvalidation();

  const { displayInfo, displayWarning, displayAlert } = useAppNotifications();

  const { dismiss, resync } = useAdminNotificationToasts();

  const announce = (notification: AdminNotification) => {
    // An error waits until it is read, wherever that happens - the server
    // reports it as settled. Anything less can go on its own: the notification
    // center keeps what the toast only announces.
    const message = {
      text: notification.title,
      timeout:
        notification.severity === AdminNotificationSeverityEnum.ERROR
          ? (false as const)
          : 10_000,
      to: { name: "admin-notifications" },
      tag: toastTag(notification.id),
    };

    // A repeat report folds into the unread row, so its toast replaces the
    // earlier one rather than stacking beside it.
    dismiss([notification.id]);

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

  // A settle only refreshes the count: refetching the list would reorder it
  // under the reader, who has just opened the notification it reports.
  const received = (message: AdminNotificationsData) => {
    if ("settledIds" in message) {
      invalidateUnreadCount();
      dismiss(message.settledIds);

      return;
    }

    invalidate();
    announce(message);
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
      void resync();
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
