import { type AdminNotificationQuery } from "@/services/fyAdminApi";
import { useFilters } from "@/shared/composables/useFilters";

// The tab lives in the route so it survives a reload, but it selects a list
// rather than narrowing one - `useFilters` has to leave it out of "a filter is
// active", the way the model lists do with their fleetchart view switch.
export const NOTIFICATION_TAB_QUERY_KEY = "t";

// The notification open as a page of its own on a phone. In the route so the
// back gesture closes it, and not a filter either.
export const NOTIFICATION_DETAIL_QUERY_KEY = "notification";

export const useAdminNotificationFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  return useFilters<AdminNotificationQuery>({
    ignoreKeys: [NOTIFICATION_TAB_QUERY_KEY],
    viewKeys: [NOTIFICATION_DETAIL_QUERY_KEY],
    updateCallback,
  });
};
