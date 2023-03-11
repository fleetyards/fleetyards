import { watch, ref, onMounted, onUnmounted } from "vue";
import { displayInfo } from "@/frontend/lib/Noty";
import { useSessionStore } from "@/frontend/stores/Session";
import { useAppStore } from "@/frontend/stores/App";
import { useHangarStore } from "@/frontend/stores/Hangar";
import { useWishlistStore } from "@/frontend/stores/Wishlist";
import { useCable } from "@/frontend/composables/useCable";
import { useI18n } from "@/frontend/composables/useI18n";
import type { Subscription } from "@rails/actioncable";

interface Channel {
  appVersion?: Subscription;
  hangarCreate?: Subscription;
  hangarDestroy?: Subscription;
  wishlistCreate?: Subscription;
  wishlistDestroy?: Subscription;
  onSaleHangar?: Subscription;
  onSale?: Subscription;
}

export const useUpdates = () => {
  const channels = ref<Channel>({});

  const sessionStore = useSessionStore();

  const unsubscribeChannel = (channel: string) => {
    channels.value[channel].unsubscribe();
    delete channels[channel];
  };

  const { consumer: cable, refresh } = useCable();

  const disconnectUpdates = () => {
    Object.keys(channels.value).forEach((channel) => {
      unsubscribeChannel(channel);
    });

    refresh();
  };

  const connected = (channel: string) => {
    console.info("Connected to Channel:", channel);
  };

  const disconnected = (channel: string) => {
    unsubscribeChannel(channel);
    console.info("Disconnected from Channel:", channel);
  };

  const appStore = useAppStore();

  const updateAppVersion = (data: string) => {
    appStore.updateVersion(JSON.parse(data));
  };

  const setupAppVersionChannel = () => {
    channels.value.appVersion = cable.subscriptions.create(
      {
        channel: "AppVersionChannel",
      },
      {
        received: updateAppVersion,
        connected: () => {
          connected("appVersion");
        },
        disconnected: () => {
          disconnected("appVersion");
        },
      }
    );
  };

  const hangarStore = useHangarStore();

  const addShipToHangar = (data: string) => {
    const vehicle = JSON.parse(data);

    if (!vehicle.model) {
      return;
    }

    hangarStore.add(vehicle.model.slug);
  };

  const setupHangarCreateChannel = () => {
    if (channels.value.hangarCreate) {
      return;
    }

    channels.value.hangarCreate = cable.subscriptions.create(
      {
        channel: "HangarCreateChannel",
      },
      {
        received: addShipToHangar,
        connected: () => {
          connected("hangarCreate");
        },
        disconnected: () => {
          disconnected("hangarCreate");
        },
      }
    );
  };

  const removeShipFromHangar = (data: string) => {
    const vehicle = JSON.parse(data);

    if (!vehicle.model) {
      return;
    }

    hangarStore.remove(vehicle.model.slug);
  };

  const setupHangarDestroyChannel = () => {
    if (channels.value.hangarDestroy) {
      return;
    }

    channels.value.hangarDestroy = cable.subscriptions.create(
      {
        channel: "HangarDestroyChannel",
      },
      {
        received: removeShipFromHangar,
        connected: () => {
          connected("hangarDestroy");
        },
        disconnected: () => {
          disconnected("hangarDestroy");
        },
      }
    );
  };

  const wishlistStore = useWishlistStore();

  const addShipToWishlist = (data: string) => {
    const vehicle = JSON.parse(data);

    if (!vehicle.model) {
      return;
    }

    wishlistStore.add(vehicle.model.slug);
  };

  const setupWishlistCreateChannel = () => {
    if (channels.value.wishlistCreate) {
      return;
    }

    channels.value.wishlistCreate = cable.subscriptions.create(
      {
        channel: "WishlistCreateChannel",
      },
      {
        received: addShipToWishlist,
        connected: () => {
          connected("wishlistCreate");
        },
        disconnected: () => {
          disconnected("wishlistCreate");
        },
      }
    );
  };

  const removeShipFromWishlist = (data: string) => {
    const vehicle = JSON.parse(data);

    if (!vehicle.model) {
      return;
    }

    wishlistStore.remove(vehicle.model.slug);
  };

  const setupWishlistDestroyChannel = () => {
    if (channels.value.wishlistDestroy) {
      return;
    }

    channels.value.wishlistDestroy = cable.subscriptions.create(
      {
        channel: "WishlistDestroyChannel",
      },
      {
        received: removeShipFromWishlist,
        connected: () => {
          connected("wishlistDestroy");
        },
        disconnected: () => {
          disconnected("wishlistDestroy");
        },
      }
    );
  };

  const { t } = useI18n();

  const notifyVehicleOnSale = (data: string) => {
    const vehicle = JSON.parse(data);

    displayInfo({
      text: t("messages.model.onSale", {
        model: vehicle.model.name,
      }),
      icon: vehicle.model.storeImageSmall,
    });
  };

  const setupOnSaleVehiclesChannel = () => {
    if (channels.value.onSaleHangar) {
      return;
    }

    channels.value.onSaleHangar = cable.subscriptions.create(
      {
        channel: "OnSaleHangarChannel",
      },
      {
        received: notifyVehicleOnSale,
        connected: () => {
          connected("onSaleHangar");
        },
        disconnected: () => {
          disconnected("onSaleHangar");
        },
      }
    );
  };

  const notifyOnSale = (data: string) => {
    const model = JSON.parse(data);

    displayInfo({
      text: t("messages.model.onSale", { model: model.name }),
      icon: model.storeImageSmall,
    });
  };

  const setupOnSaleChannel = () => {
    if (channels.value.onSale) {
      return;
    }

    channels.value.onSale = cable.subscriptions.create(
      {
        channel: "OnSaleChannel",
      },
      {
        received: notifyOnSale,
        connected: () => {
          connected("onSale");
        },
        disconnected: () => {
          disconnected("onSale");
        },
      }
    );
  };

  const setupUpdates = () => {
    setupAppVersionChannel();

    if (sessionStore.isAuthenticated) {
      setupOnSaleVehiclesChannel();
      setupOnSaleChannel();
      setupHangarCreateChannel();
      setupHangarDestroyChannel();
      setupWishlistCreateChannel();
      setupWishlistDestroyChannel();
    }
  };

  onMounted(() => {
    setupUpdates();
  });

  onUnmounted(() => {
    disconnectUpdates();
  });

  watch(
    () => sessionStore.isAuthenticated,
    () => {
      disconnectUpdates();
      setupUpdates();
    }
  );
};
