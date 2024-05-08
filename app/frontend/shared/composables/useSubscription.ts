import { useCable } from "@/shared/composables/useCable";
import { Subscription } from "@rails/actioncable";

export enum ChannelsEnum {
  APP_VERSION = "AppVersionChannel",
  HANGAR = "HangarChannel",
  HANGAR_CREATE = "HangarCreateChannel",
  HANGAR_DESTROY = "HangarDestroyChannel",
  WISHLIST_CREATE = "WishlistCreateChannel",
  WISHLIST_DESTROY = "WishlistDestroyChannel",
  ON_SALE_HANGAR = "OnSaleHangarChannel",
  ON_SALE = "OnSaleChannel",
  ROADMAP = "RoadmapChannel",
  IMPORTS = "ImportsChannel",
}

export const useSubscription = ({
  channelName,
  received,
  connected,
  disconnected,
  enabled,
}: {
  channelName: string;
  received?: (data: string) => void;
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
