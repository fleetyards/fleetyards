import {
  type NullableVehicleOperationsGroupEnum,
  type VehiclePlaqueStyleEnum,
} from "@/services/fyApi";

// A plaque's own lines, as a ship in a hangar saves them; the ship's name and
// registry are its own.
export interface PlaqueLines {
  dedication: string | null;
  dedicationVerse: string | null;
  launchedOn: string | null;
  launchPort: string | null;
  launchPortLocationId: string | null;
  affiliation: string | null;
  plaqueCaptain: string | null;
  operationsGroup: NullableVehicleOperationsGroupEnum | null;
  plaqueStyle: VehiclePlaqueStyleEnum;
  plaqueLocale: string | null;
}
