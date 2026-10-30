import {
  ModelProductionStatusEnum,
  type Vehicle,
  type VehiclePublic,
} from "@/services/fyApi";

export const useLoadoutEditor = () => {
  // Mirrors `VehicleLoadout#ship_is_flight_ready`: a ship that cannot be flown
  // yet has no loadout to fit, and the API refuses to create one.
  const loadoutEditorAvailable = (vehicle?: Vehicle | VehiclePublic) =>
    vehicle?.model?.productionStatus === ModelProductionStatusEnum.FLIGHT_READY;

  return { loadoutEditorAvailable };
};
