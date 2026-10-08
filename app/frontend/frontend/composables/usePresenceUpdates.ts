import { storeToRefs } from "pinia";
import { useDocumentVisibility, useIntervalFn } from "@vueuse/core";
import { useSessionStore } from "@/frontend/stores/session";
import { useSubscription } from "@/shared/composables/useSubscription";
import { usePresence } from "@/shared/composables/usePresence";
import { UserPresenceChannel } from "@/services/fyCable/channels/UserPresenceChannel";

// Well inside the server's window, so a visible tab never lapses between two
// reports.
const ACTIVE_INTERVAL = 30_000;

/**
 * Follow who is online among the people the reader has an accepted
 * relationship with.
 *
 * Mounted for every signed-in client rather than only where a dot is drawn: the
 * subscription is also what keeps this client's own connection counted.
 *
 * While this tab is visible it also tells the server the reader is in front of
 * the app, which holds push notifications back on all of their devices.
 */
export const usePresenceUpdates = () => {
  const { isAuthenticated } = storeToRefs(useSessionStore());
  const { applyPresence, resetPresence } = usePresence();
  const visibility = useDocumentVisibility();

  const reportActive = () => {
    if (visibility.value !== "visible") return;

    channel.value?.perform("active").catch(() => {});
  };

  const { channel } = useSubscription({
    channel: UserPresenceChannel,
    enabled: isAuthenticated,
    received: applyPresence,
    // Nothing is replayed, so what the map held across the gap cannot be
    // trusted. The first connect is left alone: the pages have just loaded.
    connected: ({ reconnect }) => {
      if (reconnect) {
        resetPresence();
      }

      reportActive();
    },
  });

  useIntervalFn(reportActive, ACTIVE_INTERVAL);

  watch(visibility, reportActive);
};
