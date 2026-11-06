import type { HangarQuery, Vehicle, VehiclePublic } from "@/services/fyApi";
import { HangarSortFieldsEnum } from "@/frontend/stores/hangar";
import type { MetricRow } from "@/shared/composables/useModelMetricRows";
import { useI18n } from "@/shared/composables/useI18n";
import { useVehicleFirepower } from "@/frontend/composables/useVehicleFirepower";
import { formatWeaponSizes } from "@/frontend/utils/weaponSizes";
import { useListFigures } from "@/frontend/composables/useListFigures";

// The list's figures a card's details otherwise leave out, named as the list
// view's columns and sorts name them.
// A const object rather than an enum: an enum whose members reference another
// enum gets reverse mappings, so Object.values would hand back its keys too.
export const VehicleListFigureEnum = {
  WEAPONS: HangarSortFieldsEnum.WEAPONS,
  ALPHA: HangarSortFieldsEnum.ALPHA,
  BURST_DPS: HangarSortFieldsEnum.BURST_DPS,
  SUSTAINED_DPS: HangarSortFieldsEnum.SUSTAINED_DPS,
  PLEDGE_PRICE: HangarSortFieldsEnum.PLEDGE_PRICE,
} as const;

export type VehicleListFigureEnum =
  (typeof VehicleListFigureEnum)[keyof typeof VehicleListFigureEnum];

const FILTER_KEYS: Record<VehicleListFigureEnum, (keyof HangarQuery)[]> = {
  [VehicleListFigureEnum.WEAPONS]: ["maxWeaponSizeGteq", "maxWeaponSizeLteq"],
  [VehicleListFigureEnum.ALPHA]: ["alphaGteq", "alphaLteq"],
  [VehicleListFigureEnum.BURST_DPS]: ["burstDpsGteq", "burstDpsLteq"],
  [VehicleListFigureEnum.SUSTAINED_DPS]: [],
  [VehicleListFigureEnum.PLEDGE_PRICE]: [
    "pledgePriceGteq",
    "pledgePriceLteq",
    "pledgePriceIn",
  ],
};

export const useVehicleListFigures = (sort: () => string | undefined) =>
  useListFigures<VehicleListFigureEnum>(FILTER_KEYS, sort);

export const useVehicleFigureRows = () => {
  const { t, toDollar } = useI18n();
  const { firepower, sustainedRange } = useVehicleFirepower();

  const value = (
    vehicle: Vehicle | VehiclePublic,
    figure: VehicleListFigureEnum,
  ) => {
    switch (figure) {
      case VehicleListFigureEnum.WEAPONS:
        return formatWeaponSizes(vehicle.weaponSizes);
      case VehicleListFigureEnum.ALPHA:
        return firepower(vehicle.alpha);
      case VehicleListFigureEnum.BURST_DPS:
        return firepower(vehicle.burstDps);
      case VehicleListFigureEnum.SUSTAINED_DPS:
        return sustainedRange(vehicle);
      case VehicleListFigureEnum.PLEDGE_PRICE:
        return toDollar(vehicle.model.pledgePrice);
    }
  };

  return (
    vehicle: Vehicle | VehiclePublic,
    figures: VehicleListFigureEnum[],
  ): MetricRow[] =>
    figures.map((figure) => ({
      label: t(`labels.hangarTable.columns.${figure}`),
      value: value(vehicle, figure) || t("labels.not-available"),
    }));
};
