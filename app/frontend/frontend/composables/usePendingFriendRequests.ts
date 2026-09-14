import {
  FeatureFlagName,
  useFriendsPendingCount as useFriendsPendingCountQuery,
} from "@/services/fyApi";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { useSessionStore } from "@/frontend/stores/session";

// How many requests are waiting on this user, for the badges that say so.
//
// The count rather than the list: a badge every signed-in client polls should
// not carry a page of rows to count them. `useUpdates` invalidates this when a
// request arrives over the cable, so the interval only covers what was answered
// somewhere else -- the same arrangement the unread-notification badge uses.
export const usePendingFriendRequests = () => {
  const { isFeatureEnabled } = useFeatures();
  const sessionStore = useSessionStore();

  const enabled = computed(
    () =>
      sessionStore.isAuthenticated && isFeatureEnabled(FeatureFlagName.FRIENDS),
  );

  const { data } = useFriendsPendingCountQuery({
    query: { enabled, refetchInterval: 60_000, retry: false },
  });

  const count = computed(() => (enabled.value ? data.value?.count || 0 : 0));

  return { count };
};
