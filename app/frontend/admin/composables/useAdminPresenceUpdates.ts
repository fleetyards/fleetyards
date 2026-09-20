import { type Ref } from "vue";
import { useSubscription } from "@/shared/composables/useSubscription";
import { usePresence } from "@/shared/composables/usePresence";
import { AdminPresenceChannel } from "@/services/fyCableAdmin/channels/AdminPresenceChannel";

/**
 * The same transitions, unredacted — an admin sees a user who turned their
 * status off as online, which is what every other admin-only field on a user
 * already does.
 */
export const useAdminPresenceUpdates = (enabled: Ref<boolean>) => {
  const { applyPresence, resetPresence } = usePresence();

  useSubscription({
    channel: AdminPresenceChannel,
    enabled,
    received: applyPresence,
    connected: ({ reconnect }) => {
      if (reconnect) {
        resetPresence();
      }
    },
  });
};
