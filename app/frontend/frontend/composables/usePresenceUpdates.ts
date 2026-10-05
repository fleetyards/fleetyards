import { storeToRefs } from "pinia";
import { useSessionStore } from "@/frontend/stores/session";
import { useSubscription } from "@/shared/composables/useSubscription";
import { usePresence } from "@/shared/composables/usePresence";
import { UserPresenceChannel } from "@/services/fyCable/channels/UserPresenceChannel";

/**
 * Follow who is online among the people the reader has an accepted
 * relationship with.
 *
 * Mounted for every signed-in client rather than only where a dot is drawn: the
 * subscription is also what keeps this client's own connection counted.
 */
export const usePresenceUpdates = () => {
  const { isAuthenticated } = storeToRefs(useSessionStore());
  const { applyPresence, resetPresence } = usePresence();

  useSubscription({
    channel: UserPresenceChannel,
    enabled: isAuthenticated,
    received: applyPresence,
    // Nothing is replayed, so what the map held across the gap cannot be
    // trusted. The first connect is left alone: the pages have just loaded.
    connected: ({ reconnect }) => {
      if (reconnect) {
        resetPresence();
      }
    },
  });
};
