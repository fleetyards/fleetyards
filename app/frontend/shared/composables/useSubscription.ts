import { useCable } from "@/shared/composables/useCable";
import { Subscription } from "@rails/actioncable";

// Re-exported rather than hand-listed: the Ruby component derives the set from
// app/channels, so a new channel shows up here without anyone maintaining a
// second copy. The hand-written list had gone two channels stale.
export { ChannelsEnum } from "@/services/fyApi";

export const useSubscription = <T = unknown>({
  channelName,
  received,
  connected,
  disconnected,
  enabled,
}: {
  channelName: string;
  received?: (data: T) => void;
  connected?: () => void;
  disconnected?: () => void;
  enabled?: ComputedRef<boolean> | Ref<boolean>;
}) => {
  const { consumer } = useCable();

  const channel = ref<Subscription>();

  const unsubscribe = () => {
    if (channel.value) {
      channel.value.unsubscribe();
    }
  };

  const subscribe = () => {
    unsubscribe();

    if (!consumer) {
      return;
    }

    // actioncable opens the socket synchronously inside `create`, so a client
    // that cannot open one at all -- a proxy rewriting the URL, an extension,
    // a network policy blocking wss -- throws right here and used to take the
    // mount with it. Live updates are an enhancement, so the page has to work
    // without them.
    try {
      channel.value = consumer.subscriptions.create(
        {
          channel: channelName,
        },
        {
          received,
          connected: () => {
            console.info("Connected to Channel:", channelName);

            if (connected) {
              connected();
            }
          },
          // No `unsubscribe()` here: actioncable reopens the socket by
          // itself -- returning to a backgrounded tab is enough -- and
          // resubscribes everything it still knows about. Dropping the
          // subscription on the way down takes it out of that list, so the
          // channel goes quiet for good after the first reconnect.
          disconnected: () => {
            console.info("Disconnected from Channel:", channelName);

            if (disconnected) {
              disconnected();
            }
          },
        },
      );
    } catch (error) {
      console.warn("Subscriptions: could not subscribe to", channelName, error);
    }
  };

  onMounted(() => {
    if (enabled === undefined || enabled.value) {
      subscribe();
    }
  });

  onUnmounted(() => {
    unsubscribe();
  });

  watch(
    () => enabled?.value,
    (value) => {
      if (!value) {
        unsubscribe();
      } else {
        subscribe();
      }
    },
  );

  return {
    channel,
    subscribe,
    unsubscribe,
  };
};
