import type { Vehicle, VehiclePublic } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

/*
 * A vehicle's cargo as fitted. Without a loadout saying how the ship is fitted,
 * the cargo its modules would add is shown beside it rather than in its place:
 * "20 SCU (200 SCU with modules)".
 */
export const useVehicleCargo = () => {
  const { t, toNumber } = useI18n();

  const cargoOf = (vehicle: Vehicle | VehiclePublic) =>
    vehicle.cargo ?? vehicle.model.metrics.cargo ?? 0;

  const cargoLabel = (vehicle: Vehicle | VehiclePublic) => {
    const cargo = cargoOf(vehicle);

    if (!vehicle.cargoWithModules) {
      return toNumber(cargo, "cargo");
    }

    return t("labels.vehicle.cargoWithModules", {
      cargo: t("number.cargo", { count: cargo }),
      withModules: toNumber(vehicle.cargoWithModules, "cargo"),
    });
  };

  return { cargoOf, cargoLabel };
};
