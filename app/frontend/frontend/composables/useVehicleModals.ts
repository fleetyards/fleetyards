import { useComlink } from "@/shared/composables/useComlink";
import {
  type Vehicle,
  type VehicleLoadout,
  type VehicleLoadoutMinimal,
  type VehiclePublic,
  VehicleLoadoutKindEnum,
} from "@/services/fyApi";
import type { VehicleEditTabsEnum } from "@/frontend/components/Vehicles/EditModal/types";
import type { VehicleLoadoutTabsEnum } from "@/frontend/components/Vehicles/LoadoutModal/types";

// What a visitor's loadout view reads off the ship, so a ship known only by
// reference, as a fleet event signup knows it, can open one too.
export type LoadoutViewVehicle = Pick<
  VehiclePublic,
  "id" | "name" | "image" | "model" | "activeLoadout"
>;

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
      wide: true,
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
      // Most of the screen, as the configuration terminal takes it: the ship is
      // the backdrop and the choices need the width.
      large: true,
      props: {
        vehicle,
        editable: options.editable ?? false,
        tab: options.tab,
        loadoutId: options.loadoutId,
        newLoadout: options.newLoadout ?? false,
      },
    });
  };

  // A loadout to look at rather than edit: the active fleetyards loadout unless
  // another is named. A linked build is read on its own site.
  const openLoadoutView = (
    vehicle: Vehicle | LoadoutViewVehicle,
    options: {
      editable?: boolean;
      loadout?: VehicleLoadout | VehicleLoadoutMinimal;
    } = {},
  ) => {
    const active =
      vehicle.activeLoadout?.kind === VehicleLoadoutKindEnum.FLEETYARDS
        ? vehicle.activeLoadout
        : undefined;

    comlink.emit("open-modal", {
      component: () =>
        import("@/frontend/components/Vehicles/LoadoutView/index.vue"),
      wide: true,
      props: {
        vehicle,
        loadout: options.loadout ?? active,
        editable: options.editable ?? false,
      },
    });
  };

  return { openEditModal, openLoadoutModal, openLoadoutView };
};
