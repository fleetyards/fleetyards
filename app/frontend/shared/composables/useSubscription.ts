import { getCable } from "@/shared/utils/Cable";
import type { Channel, ChannelEvents, Message } from "@anycable/core";

// What anycable reports when a channel connects: `reconnect` tells a
// resubscribe apart from the first connect, `restored` a session the server
// picked up where it left off.
export type ConnectEvent = Parameters<ChannelEvents<Message>["connect"]>[0];

// A generated channel class. None of them takes client-supplied params -- every
// channel streams for the connection's own user -- so the app subscribes by
// handing over the class and the payload type follows from the contract.
type SubscribableChannel<T extends Message> = {
  new (): Channel<Record<string, never>, T>;
  readonly identifier: string;
};

export const useSubscription = <T extends Message>({
  channel,
  received,
  connected,
  disconnected,
  enabled,
}: {
  channel: SubscribableChannel<T>;
  received?: (data: T) => void;
  connected?: (event: ConnectEvent) => void;
  disconnected?: () => void;
  enabled?: ComputedRef<boolean> | Ref<boolean>;
}) => {
  const { identifier } = channel;

  // Shallow: anycable looks its channels up by identity, so a reactive proxy
  // around one would never match the instance the cable holds.
  const subscription = shallowRef<Channel<Record<string, never>, T>>();

  const unsubscribe = () => {
    if (!subscription.value) {
      return;
    }

    subscription.value.disconnect();
    subscription.value = undefined;
  };

  const subscribe = () => {
    unsubscribe();

    const cable = getCable();

    if (!cable) {
      return;
    }

    // A fresh instance per subscribe: a channel that has been disconnected
    // clears its receiver asynchronously, and one that is still attached is
    // returned unchanged by `subscribe`.
    const instance = new channel();

    instance.on("message", (data) => received?.(data));

    // No `unsubscribe()` on the way down: anycable reopens the socket by itself
    // -- returning to a backgrounded tab is enough -- and resubscribes every
    // channel it still holds. Dropping the subscription takes it out of that
    // set, so the channel would go quiet for good after the first reconnect.
    instance.on("disconnect", (error) => {
      console.info("Disconnected from Channel:", identifier, error?.message);

      disconnected?.();
    });

    // `reconnect` tells a resubscribe apart from the first connect. Nothing is
    // replayed, so a consumer that has to catch up resyncs from here.
    instance.on("connect", (event) => {
      console.info("Connected to Channel:", identifier);

      connected?.(event);
    });

    // The subscription itself was refused -- an unauthenticated connection, a
    // channel that rejects -- rather than the socket going down.
    instance.on("close", (error) => {
      if (error) {
        console.warn("Subscriptions: closed", identifier, error.message);
      }
    });

    subscription.value = cable.subscribe(instance);
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
    channel: subscription,
    subscribe,
    unsubscribe,
  };
};
