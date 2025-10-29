import { type HangarQuery } from "@/services/fyApi";
import { useFilters } from "@/shared/composables/useFilters";

export const useHangarFilters = (updateCallback?: () => void) => {
  return useFilters<HangarQuery>({
    allowedKeys: [
      "searchCont",
      "nameCont",
      "onSaleEq",
      "loanerEq",
      "publicEq",
      "boughtViaEq",
      "hangarGroupsIn",
      "hangarGroupsNotIn",
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
      "withCargo",
    ],
    ignoreKeys: ["fleetchart"],
    updateCallback,
  });
};
