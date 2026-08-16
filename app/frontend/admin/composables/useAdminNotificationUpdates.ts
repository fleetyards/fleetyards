import { type Ref } from "vue";
import { useQueryClient } from "@tanstack/vue-query";
import {
  useSubscription,
  ChannelsEnum,
} from "@/shared/composables/useSubscription";
import {
  getAdminNotificationsQueryKey,
  getAdminNotificationsUnreadCountQueryKey,
} from "@/services/fyAdminApi";

export const useAdminNotificationUpdates = (enabled: Ref<boolean>) => {
  const queryClient = useQueryClient();

  const invalidate = () => {
    void queryClient.invalidateQueries({
      queryKey: getAdminNotificationsQueryKey(),
    });
    void queryClient.invalidateQueries({
      queryKey: getAdminNotificationsUnreadCountQueryKey(),
    });
  };

  useSubscription({
    channelName: ChannelsEnum.ADMIN_NOTIFICATIONS,
    received: invalidate,
    enabled,
  });

  return { invalidate };
};
