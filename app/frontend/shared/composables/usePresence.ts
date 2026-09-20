/** One user's presence, as the cable last reported it. */
export interface PresenceUpdate {
  userId: string;
  online: boolean;
  lastActiveAt?: string | null;
}

interface PresenceState {
  online: boolean;
  lastActiveAt?: string | null;
}

/*
 * Module-level rather than per-caller: a roster, a friends list and a member
 * modal open at once are three readers of one fact, and the subscription that
 * writes it is mounted once for the whole app.
 *
 * Shared by both apps. The public and the admin cable carry the same message —
 * the admin one unredacted — so a surface reads the same map whichever
 * subscription filled it.
 */
const presence = reactive(new Map<string, PresenceState>());

export const usePresence = () => {
  const applyPresence = (update: PresenceUpdate) => {
    presence.set(update.userId, {
      online: update.online,
      lastActiveAt: update.lastActiveAt,
    });
  };

  /*
   * Nothing broadcast while the socket was down is replayed, so everything held
   * across the gap is unverifiable. Dropping it falls the surfaces back to what
   * their own payload said, which is the worst case they already handle.
   */
  const resetPresence = () => {
    presence.clear();
  };

  /*
   * The map wins over the payload where it has an answer: a transition is
   * newer than the list it is patching, and a list is only refetched when
   * something else asks it to be.
   */
  const isOnline = (
    userId: string | undefined | null,
    fallback?: boolean | null,
  ) => (userId ? presence.get(userId)?.online : undefined) ?? fallback ?? false;

  /*
   * A roster falls back to "Last Active" once the dot goes grey, and the
   * transition is the moment that changes — so the message carries it and the
   * column reads it from here.
   */
  const lastActiveAt = (
    userId: string | undefined | null,
    fallback?: string | null,
  ) => {
    const known = userId ? presence.get(userId) : undefined;

    return known ? (known.lastActiveAt ?? fallback) : fallback;
  };

  return {
    applyPresence,
    resetPresence,
    isOnline,
    lastActiveAt,
  };
};
