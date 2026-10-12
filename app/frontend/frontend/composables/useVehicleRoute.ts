import { type RouteLocationRaw } from "vue-router";
import { useSessionStore } from "@/frontend/stores/session";
import {
  type VehicleRouteName,
  vehicleRoute,
} from "@/frontend/utils/vehicleSegment";

// Vehicle pages are their owner's alone, so every link to one is a link into
// the reader's own hangar.
export const useVehicleRoute = () => {
  const sessionStore = useSessionStore();

  return (
    name: VehicleRouteName,
    vehicle: Parameters<typeof vehicleRoute>[1],
    params: Record<string, string> = {},
  ): RouteLocationRaw => {
    const username = sessionStore.currentUser?.username;

    // The old address still resolves, through the redirect that maps it here.
    if (!username) return `/hangar/${vehicle.id}/`;

    return vehicleRoute(name, vehicle, username, params);
  };
};
