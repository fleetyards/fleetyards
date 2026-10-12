import { type RouteLocationRaw } from "vue-router";
import { useSessionStore } from "@/frontend/stores/session";
import {
  type VehicleRouteName,
  vehicleRoute,
} from "@/frontend/utils/vehicleSegment";

const LEGACY_PATHS: Record<
  VehicleRouteName,
  (params: Record<string, string>) => string
> = {
  "hangar-vehicle": () => "loadouts/",
  "hangar-vehicle-overview": () => "overview/",
  "hangar-vehicle-log": () => "log/",
  "hangar-vehicle-loadouts": () => "loadouts/",
  "hangar-vehicle-cargo": () => "cargo/",
  "hangar-vehicle-cargo-item": (params) => `cargo/${params.item}/`,
};

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

    // The old addresses still resolve, through the redirects that map them
    // here. A bare `/hangar/:id/` does not: it is the public hangar's shape.
    if (!username) {
      return `/hangar/${vehicle.id}/${LEGACY_PATHS[name](params)}`;
    }

    return vehicleRoute(name, vehicle, username, params);
  };
};
