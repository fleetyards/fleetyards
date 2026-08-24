import { type AdminNotificationQuery } from "@/services/fyAdminApi";
import { useFilters } from "@/shared/composables/useFilters";

// The tab lives in the route so it survives a reload, but it selects a list
// rather than narrowing one - `useFilters` has to leave it out of "a filter is
// active", the way the model lists do with their fleetchart view switch.
export const NOTIFICATION_TAB_QUERY_KEY = "t";

export const useAdminNotificationFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  return useFilters<AdminNotificationQuery>({
    ignoreKeys: [NOTIFICATION_TAB_QUERY_KEY],
    updateCallback,
  });
};
