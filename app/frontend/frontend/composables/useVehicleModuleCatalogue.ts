import {
  type Vehicle,
  type VehiclePublic,
  useModelModules,
} from "@/services/fyApi";

// The largest page the endpoint serves, so an owned module past the first page
// stays listed, and the ship's id, so one the catalogue has since hidden does.
export const useVehicleModuleCatalogue = (
  vehicle: () => Vehicle | VehiclePublic,
  enabled: MaybeRefOrGetter<boolean> = true,
) =>
  useModelModules(
    () => vehicle().model?.slug ?? "",
    computed(() => ({ perPage: "100", vehicleId: vehicle().id })),
    { query: { enabled } },
  );
