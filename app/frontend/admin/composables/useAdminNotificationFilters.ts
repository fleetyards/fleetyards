import { type AdminNotificationQuery } from "@/services/fyAdminApi";
import { useFilters } from "@/shared/composables/useFilters";

export const useAdminNotificationFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  return useFilters<AdminNotificationQuery>({
    updateCallback,
  });
};
