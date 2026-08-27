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
        disconnected: () => {
          unsubscribe();

          console.info("Disconnected from Channel:", channelName);

          if (disconnected) {
            disconnected();
          }
        },
      },
    );
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
