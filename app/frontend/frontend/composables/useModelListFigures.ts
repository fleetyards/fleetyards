import type { Model, ModelQuery } from "@/services/fyApi";
import { ModelSortFieldsEnum } from "@/frontend/stores/models";
import type { MetricRow } from "@/shared/composables/useModelMetricRows";
import { useI18n } from "@/shared/composables/useI18n";
import { useListFigures } from "@/frontend/composables/useListFigures";
import { useVehicleFirepower } from "@/frontend/composables/useVehicleFirepower";
import { formatWeaponSizes } from "@/frontend/utils/weaponSizes";

// The list's figures a card's details otherwise leave out, named as the list
// view's columns and sorts name them.
// A const object rather than an enum: an enum whose members reference another
// enum gets reverse mappings, so Object.values would hand back its keys too.
export const ModelListFigureEnum = {
  WEAPONS: ModelSortFieldsEnum.WEAPONS,
  ALPHA: ModelSortFieldsEnum.ALPHA,
  BURST_DPS: ModelSortFieldsEnum.BURST_DPS,
  SUSTAINED_DPS: ModelSortFieldsEnum.SUSTAINED_DPS,
  PLEDGE_PRICE: ModelSortFieldsEnum.PLEDGE_PRICE,
} as const;

export type ModelListFigureEnum =
  (typeof ModelListFigureEnum)[keyof typeof ModelListFigureEnum];

const FILTER_KEYS: Record<ModelListFigureEnum, (keyof ModelQuery)[]> = {
  [ModelListFigureEnum.WEAPONS]: [],
  [ModelListFigureEnum.ALPHA]: [],
  [ModelListFigureEnum.BURST_DPS]: [],
  [ModelListFigureEnum.SUSTAINED_DPS]: [],
  [ModelListFigureEnum.PLEDGE_PRICE]: [
    "pledgePriceGteq",
    "pledgePriceLteq",
    "pledgePriceIn",
  ],
};

export const useModelListFigures = (sort: () => string | undefined) =>
  useListFigures<ModelListFigureEnum>(FILTER_KEYS, sort);

export const useModelFigureRows = () => {
  const { t, toDollar } = useI18n();
  const { firepower, sustainedRange } = useVehicleFirepower();

  const value = (model: Model, figure: ModelListFigureEnum) => {
    switch (figure) {
      case ModelListFigureEnum.WEAPONS:
        return formatWeaponSizes(model.weaponSizes);
      case ModelListFigureEnum.ALPHA:
        return firepower(model.alpha);
      case ModelListFigureEnum.BURST_DPS:
        return firepower(model.burstDps);
      case ModelListFigureEnum.SUSTAINED_DPS:
        return sustainedRange(model);
      case ModelListFigureEnum.PLEDGE_PRICE:
        return toDollar(model.pledgePrice);
    }
  };

  return (model: Model, figures: ModelListFigureEnum[]): MetricRow[] =>
    figures.map((figure) => ({
      label: t(`labels.models.table.columns.${figure}`),
      value: value(model, figure) || t("labels.not-available"),
    }));
};
