import { type Ref } from "vue";
import { useQueryClient } from "@tanstack/vue-query";
import {
  useSubscription,
  type ConnectEvent,
} from "@/shared/composables/useSubscription";
import {
  AdminAnnouncementsChannel,
  type AdminAnnouncementsData,
} from "@/services/fyCableAdmin/channels/AdminAnnouncementsChannel";
import {
  getAnnouncementQueryKey,
  getAnnouncementsQueryKey,
  type Announcement,
  type Announcements,
} from "@/services/fyAdminApi";

export const useAnnouncementInvalidation = () => {
  const queryClient = useQueryClient();

  const invalidate = () => {
    void queryClient.invalidateQueries({
      queryKey: getAnnouncementsQueryKey(),
    });
  };

  // Swapped into the cache rather than refetched. One publish emits up to ten
  // broadcasts - a status change, a pending row per channel and an outcome per
  // channel - and invalidating on each would refetch the list ten times and
  // reorder it under whoever is reading it. Same call the admin notification
  // list already makes.
  const patchCached = (announcement: Announcement) => {
    queryClient.setQueriesData<Announcements>(
      { queryKey: getAnnouncementsQueryKey() },
      (data) => {
        // `['announcements']` is a prefix of `['announcements', id]`, so this
        // matches the detail query too - and its payload is a bare
        // announcement, with no `items` to map over.
        if (!data?.items) {
          return data;
        }

        // A row this page has not got - another admin's new announcement, or one
        // that belongs on a page this reader is not on. Nothing to patch, and
        // inserting it would put it in the wrong place in the sort.
        if (!data.items.some((item) => item.id === announcement.id)) {
          return data;
        }

        return {
          ...data,
          items: data.items.map((item) =>
            item.id === announcement.id ? announcement : item,
          ),
        };
      },
    );

    // The detail layout holds its own query, so the edit page's deliveries
    // settle from the same broadcast the list does.
    queryClient.setQueryData<Announcement>(
      getAnnouncementQueryKey(announcement.id),
      (data) => (data ? announcement : data),
    );
  };

  return { invalidate, patchCached };
};

// Whatever was broadcast while the socket was down is gone - the channel has no
// replay - so a reconnect resyncs rather than carries on. A send that finished
// in the gap would otherwise leave the list sitting on `publishing` for good,
// which is the one state it is least safe to be wrong about.
export const useAnnouncementUpdates = (enabled?: Ref<boolean>) => {
  const { invalidate, patchCached } = useAnnouncementInvalidation();

  const connected = ({ reconnect }: ConnectEvent) => {
    if (reconnect) {
      invalidate();
    }
  };

  useSubscription({
    channel: AdminAnnouncementsChannel,
    received: (announcement: AdminAnnouncementsData) =>
      patchCached(announcement),
    connected,
    enabled,
  });

  return { invalidate, patchCached };
};
