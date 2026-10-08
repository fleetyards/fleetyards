import { storeToRefs } from "pinia";
import { useDocumentVisibility, useIdle, useIntervalFn } from "@vueuse/core";
import { useSessionStore } from "@/frontend/stores/session";
import { useSubscription } from "@/shared/composables/useSubscription";
import { usePresence } from "@/shared/composables/usePresence";
import { UserPresenceChannel } from "@/services/fyCable/channels/UserPresenceChannel";

// Well inside the server's window, so a tab in use never lapses between two
// reports.
const ACTIVE_INTERVAL = 30_000;

// A visible tab is not a reader: a laptop left on a fleetyards page stays
// visible all night, and would hold back every push to the phone with it.
// Long enough to sit and watch a sync finish without touching anything.
const IDLE_AFTER = 5 * 60_000;

/**
 * Follow who is online among the people the reader has an accepted
 * relationship with.
 *
 * Mounted for every signed-in client rather than only where a dot is drawn: the
 * subscription is also what keeps this client's own connection counted.
 *
 * While this tab is visible and in use it also tells the server the reader is
 * in front of the app, which holds push notifications back on all of their
 * devices.
 */
export const usePresenceUpdates = () => {
  const { isAuthenticated } = storeToRefs(useSessionStore());
  const { applyPresence, resetPresence } = usePresence();
  const visibility = useDocumentVisibility();
  const { idle } = useIdle(IDLE_AFTER);

  // A report into a socket that is down only fails; the reconnect reports
  // afresh instead.
  const connected = ref(false);

  const inUse = computed(
    () =>
      isAuthenticated.value &&
      connected.value &&
      visibility.value === "visible" &&
      !idle.value,
  );

  const report = (action: "active" | "inactive") => {
    channel.value?.perform(action).catch((error: Error) => {
      console.warn("Presence: report failed", action, error.message);
    });
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

      connected.value = true;
    },
    disconnected: () => {
      connected.value = false;
    },
  });

  // Signing out drops the subscription without a disconnect event, and the
  // next sign-in must wait for its own connect.
  watch(isAuthenticated, (value) => {
    if (!value) {
      connected.value = false;
    }
  });

  const { pause, resume } = useIntervalFn(
    () => report("active"),
    ACTIVE_INTERVAL,
    { immediate: false },
  );

  watch(inUse, (value) => {
    if (value) {
      report("active");
      resume();
    } else {
      pause();
    }
  });

  // Hiding the tab keeps the server's window, which covers a quick look at
  // another app. Going idle means the reader has walked away. Either way only
  // this tab's own entry changes, so another tab in use is unaffected.
  watch(idle, (value) => {
    if (value && connected.value) {
      report("inactive");
    }
  });
};
