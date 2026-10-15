import {
  FeatureFlagName,
  ModelProductionStatusEnum,
  type Vehicle,
  type VehiclePublic,
} from "@/services/fyApi";
import { useFeatures } from "@/frontend/composables/useFeatures";

export const useLoadoutEditor = () => {
  const { isFeatureEnabled } = useFeatures();

  // Mirrors `VehicleLoadout#ship_is_flight_ready`: a ship that cannot be flown
  // yet has no loadout to fit, and the API refuses to create one.
  const loadoutEditorAvailable = (vehicle?: Vehicle | VehiclePublic) =>
    isFeatureEnabled(FeatureFlagName.LOADOUT_EDITOR) &&
    vehicle?.model?.productionStatus === ModelProductionStatusEnum.FLIGHT_READY;

  return { loadoutEditorAvailable };
};
