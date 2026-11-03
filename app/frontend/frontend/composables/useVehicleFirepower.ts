import type { Vehicle, VehiclePublic } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Firepower = Pick<
  Vehicle | VehiclePublic,
  "sustainedDpsMin" | "sustainedDpsMax"
>;

export const useVehicleFirepower = () => {
  const { toNumber } = useI18n();

  // No figure is blank, where a gun that does not fire at one pip reads 0.
  const firepower = (value?: number | null) =>
    value == null ? "" : String(toNumber(Math.round(value), "integer"));

  // Sustained fire from one weapon pip to the most the plant gives; a ship
  // whose guns do not care about power shows the one figure.
  const sustainedRange = (vehicle: Firepower) => {
    const min = firepower(vehicle.sustainedDpsMin);
    const max = firepower(vehicle.sustainedDpsMax);

    return !min || min === max ? max : `${min}–${max}`;
  };

  return { firepower, sustainedRange };
};
