import { type ModelPaintQuery } from "@/services/fyAdminApi";
import { useFilters } from "@/shared/composables/useFilters";

interface AllowedFilters extends ModelPaintQuery {}

export const useModelPaintFilters = (updateCallback?: () => void) => {
  return useFilters<AllowedFilters>({
    allowedKeys: [
      "nameCont",
      "nameEq",
      "nameCont",
      "idEq",
      "nameIn",
      "idIn",
      "idNotIn",
      "modelSlugIn",
      "modelSlugEq",
    ],
    updateCallback,
  });
};
