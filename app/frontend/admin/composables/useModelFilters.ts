import { type ModelQuery } from "@/services/fyAdminApi";
import { useFilters } from "@/shared/composables/useFilters";

interface AllowedFilters extends ModelQuery {}

export const useModelFilters = (updateCallback?: () => void) => {
  return useFilters<AllowedFilters>({
    allowedKeys: [
      "searchCont",
      "nameCont",
      "scIdentifierBlank",
      "fleetchartImageBlank",
      "holoBlank",
      "topViewColoredBlank",
      "frontViewBlank",
      "manufacturerIn",
      "productionStatusIn",
    ],
    updateCallback,
  });
};
