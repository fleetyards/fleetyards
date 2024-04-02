import { useSessionStore } from "@/frontend/stores/session";
import { useAppStore } from "@/frontend/stores/app";
import { useHangarStore } from "@/frontend/stores/hangar";
import { useWishlistStore } from "@/frontend/stores/wishlist";
import { useNoty } from "@/shared/composables/useNoty";
import { useI18n } from "@/shared/composables/useI18n";
import {
  useSubscription,
  ChannelsEnum,
} from "@/shared/composables/useSubscription";
import { storeToRefs } from "pinia";

export const useUpdates = () => {
  const appStore = useAppStore();

  const updateAppVersion = (data: string) => {
    appStore.updateVersion(JSON.parse(data));
  };

  const hangarStore = useHangarStore();

  const addShipToHangar = (data: string) => {
    const vehicle = JSON.parse(data);

    if (!vehicle.model) {
      return;
    }

    hangarStore.add(vehicle.model.slug);
  };

  const removeShipFromHangar = (data: string) => {
    const vehicle = JSON.parse(data);

    if (!vehicle.model) {
      return;
    }

    hangarStore.remove(vehicle.model.slug);
  };

  const wishlistStore = useWishlistStore();

  const addShipToWishlist = (data: string) => {
    const vehicle = JSON.parse(data);

    if (!vehicle.model) {
      return;
    }

    wishlistStore.add(vehicle.model.slug);
  };

  const removeShipFromWishlist = (data: string) => {
    const vehicle = JSON.parse(data);

    if (!vehicle.model) {
      return;
    }

    wishlistStore.remove(vehicle.model.slug);
  };

  const { t } = useI18n();
  const { displayInfo } = useNoty();

  const notifyVehicleOnSale = (data: string) => {
    const vehicle = JSON.parse(data);

    displayInfo({
      text: t("messages.model.onSale", {
        model: vehicle.model.name,
      }),
      icon: vehicle.model.storeImageSmall,
    });
  };

  const notifyOnSale = (data: string) => {
    const model = JSON.parse(data);

    displayInfo({
      text: t("messages.model.onSale", { model: model.name }),
      icon: model.storeImageSmall,
    });
  };

  const sessionStore = useSessionStore();

  const { isAuthenticated } = storeToRefs(sessionStore);

  useSubscription({
    channelName: ChannelsEnum.APP_VERSION,
    received: updateAppVersion,
  });
  useSubscription({
    channelName: ChannelsEnum.ON_SALE_HANGAR,
    received: notifyVehicleOnSale,
    enabled: isAuthenticated,
  });
  useSubscription({
    channelName: ChannelsEnum.ON_SALE,
    received: notifyOnSale,
    enabled: isAuthenticated,
  });
  useSubscription({
    channelName: ChannelsEnum.HANGAR_CREATE,
    received: addShipToHangar,
    enabled: isAuthenticated,
  });
  useSubscription({
    channelName: ChannelsEnum.HANGAR_DESTROY,
    received: removeShipFromHangar,
    enabled: isAuthenticated,
  });
  useSubscription({
    channelName: ChannelsEnum.WISHLIST_CREATE,
    received: addShipToWishlist,
    enabled: isAuthenticated,
  });
  useSubscription({
    channelName: ChannelsEnum.WISHLIST_DESTROY,
    received: removeShipFromWishlist,
    enabled: isAuthenticated,
  });
};
