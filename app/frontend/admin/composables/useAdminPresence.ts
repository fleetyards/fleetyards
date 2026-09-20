import { usePresence } from "@/shared/composables/usePresence";

/** Anything an admin row knows about the user in it. */
export interface AdminPresenceSubject {
  userId?: string | null;
  online?: boolean;
  lastActiveAt?: string | null;
}

/**
 * The admin twin of `useMemberPresence`, without its two gates: the truth is
 * not behind the `online_status` flag here, and `show_online_status` is a
 * promise to co-members and friends rather than to the people running the site.
 */
export const useAdminPresence = () => {
  const { isOnline, lastActiveAt } = usePresence();

  const onlineFor = (subject: AdminPresenceSubject) => {
    if (subject.online === undefined) {
      return undefined;
    }

    return isOnline(subject.userId, subject.online);
  };

  const lastActiveAtFor = (subject: AdminPresenceSubject) =>
    lastActiveAt(subject.userId, subject.lastActiveAt);

  return {
    onlineFor,
    lastActiveAtFor,
  };
};
