import {
  FeatureFlagName,
  type MediaFile,
  type Vehicle,
  type VehiclePublic,
} from "@/services/fyApi";
import { useFeatures } from "@/frontend/composables/useFeatures";

// A picture the owner uploaded comes before every stock render, the paint's
// included. Grouped fleet rows are models rather than vehicles and carry no
// `image`, so they fall through to the stock render on their own.
export const useVehicleImage = () => {
  const { isFeatureEnabled } = useFeatures();

  const uploadedImage = (
    vehicle: Pick<Vehicle | VehiclePublic, "image"> | undefined | null,
  ): MediaFile | undefined => {
    if (!isFeatureEnabled(FeatureFlagName.VEHICLE_OVERVIEW)) return undefined;

    return vehicle?.image ?? undefined;
  };

  return { uploadedImage };
};
