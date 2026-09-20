import { useFeatures } from "@/frontend/composables/useFeatures";
import { usePresence } from "@/shared/composables/usePresence";
import { FeatureFlagName } from "@/services/fyApi";

/** Anything a row knows about the person in it. */
export interface PresenceSubject {
  userId?: string | null;
  online?: boolean;
  lastActiveAt?: string | null;
}

/**
 * The dot as a surface should read it: the live map where it has an answer,
 * the payload the page arrived with otherwise, and nothing at all where the
 * reader is not entitled to one.
 */
export const useMemberPresence = () => {
  const { isFeatureEnabled } = useFeatures();
  const { isOnline, lastActiveAt } = usePresence();

  const presenceEnabled = computed(() =>
    isFeatureEnabled(FeatureFlagName.ONLINE_STATUS),
  );

  /*
   * `undefined` means no dot. A row whose payload carried no `online` is one
   * the API declined to answer for — a fleet on the shared alliance view, or a
   * reader with the flag off — and drawing a grey dot there would assert
   * something nobody said.
   */
  const onlineFor = (subject: PresenceSubject) => {
    if (!presenceEnabled.value || subject.online === undefined) {
      return undefined;
    }

    return isOnline(subject.userId, subject.online);
  };

  const lastActiveAtFor = (subject: PresenceSubject) =>
    lastActiveAt(subject.userId, subject.lastActiveAt);

  return {
    presenceEnabled,
    onlineFor,
    lastActiveAtFor,
  };
};
