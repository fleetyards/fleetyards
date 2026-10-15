import { useComlink } from "@/shared/composables/useComlink";
import type { Vehicle, VehiclePublic } from "@/services/fyApi";
import type { VehicleEditTabsEnum } from "@/frontend/components/Vehicles/EditModal/types";
import type { VehicleLoadoutTabsEnum } from "@/frontend/components/Vehicles/LoadoutModal/types";

export const useVehicleModals = () => {
  const comlink = useComlink();

  const openEditModal = (
    vehicle: Vehicle,
    options: {
      tab?: VehicleEditTabsEnum;
      wishlist?: boolean;
      paintId?: string;
    } = {},
  ) => {
    comlink.emit("open-modal", {
      component: () =>
        import("@/frontend/components/Vehicles/EditModal/index.vue"),
      props: {
        vehicle,
        wishlist: options.wishlist ?? vehicle.wanted,
        tab: options.tab,
        paintId: options.paintId,
      },
    });
  };

  const openLoadoutModal = (
    vehicle: Vehicle | VehiclePublic,
    options: {
      tab?: VehicleLoadoutTabsEnum;
      editable?: boolean;
      loadoutId?: string;
      newLoadout?: boolean;
    } = {},
  ) => {
    comlink.emit("open-modal", {
      component: () =>
        import("@/frontend/components/Vehicles/LoadoutModal/index.vue"),
      wide: true,
      props: {
        vehicle,
        editable: options.editable ?? false,
        tab: options.tab,
        loadoutId: options.loadoutId,
        newLoadout: options.newLoadout ?? false,
      },
    });
  };

  return { openEditModal, openLoadoutModal };
};
