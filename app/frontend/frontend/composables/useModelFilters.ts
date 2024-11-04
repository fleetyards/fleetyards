import { type ModelQuery } from "@/services/fyApi";
import { useFilters } from "@/shared/composables/useFilters";

interface AllowedFilters extends ModelQuery {
  fleetchart?: boolean;
}

export const useModelFilters = (updateCallback?: () => void) => {
  return useFilters<AllowedFilters>({
    allowedKeys: [
      "searchCont",
      "nameCont",
      "onSaleEq",
      "priceLteq",
      "priceGteq",
      "pledgePriceLteq",
      "pledgePriceGteq",
      "lengthLteq",
      "lengthGteq",
      "beamLteq",
      "beamGteq",
      "heightLteq",
      "heightGteq",
      "willItFit",
      "manufacturerIn",
      "classificationIn",
      "focusIn",
      "productionStatusIn",
      "priceIn",
      "pledgePriceIn",
      "sizeIn",
      "fleetchart",
    ],
    ignoreKeys: ["fleetchart"],
    updateCallback,
  });
};
