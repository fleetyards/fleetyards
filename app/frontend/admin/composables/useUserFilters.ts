import { type UserQuery } from "@/services/fyAdminApi";
import { useFilters } from "@/shared/composables/useFilters";

export const useUserFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  return useFilters<UserQuery>({
    updateCallback,
  });
};
