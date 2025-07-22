import { type UserQuery } from "@/services/fyAdminApi";
import { useFilters } from "@/shared/composables/useFilters";

interface AllowedFilters extends UserQuery {}

export const useUserFilters = (updateCallback?: () => void) => {
  return useFilters<AllowedFilters>({
    allowedKeys: ["searchCont", "usernameCont", "emailCont"],
    updateCallback,
  });
};
