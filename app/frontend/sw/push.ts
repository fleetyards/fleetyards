// What the service worker does with a push, kept out of the worker itself so
// it can be tested: the worker only wires these to its events.

export type PushPayload = {
  title: string;
  body?: string;
  url?: string;
  tag?: string;
  notificationId?: string;
};

export const FALLBACK_TITLE = "FleetYards";

// A push has to end in a visible notification -- browsers revoke the
// permission of a site that receives pushes silently -- so anything unreadable
// still shows something.
export const parsePushPayload = (text?: string | null): PushPayload => {
  if (!text) return { title: FALLBACK_TITLE };

  try {
    const data = JSON.parse(text);
    if (data && typeof data.title === "string" && data.title.length > 0) {
      return data as PushPayload;
    }
  } catch {
    // fall through to the generic notification
  }

  return { title: FALLBACK_TITLE };
};

// Only this origin: a link anywhere else opens the site instead.
export const safeUrl = (url: unknown, origin: string): string => {
  const fallback = `${origin}/`;
  if (typeof url !== "string" || url.length === 0) return fallback;

  try {
    const parsed = new URL(url, origin);
    return parsed.origin === origin ? parsed.href : fallback;
  } catch {
    return fallback;
  }
};

export const notificationOptions = (
  payload: PushPayload,
  origin: string,
  icon: string,
): NotificationOptions => ({
  body: payload.body,
  icon,
  tag: payload.tag,
  data: {
    url: safeUrl(payload.url, origin),
    notificationId: payload.notificationId,
  },
});

// A tab already on the page is focused as it is; any other tab of the site is
// focused and sent there; with none open, a new window is.
export const pickClient = <T extends { url: string }>(
  clients: readonly T[],
  url: string,
  origin: string,
): { client: T; navigate: boolean } | undefined => {
  const exact = clients.find((client) => client.url === url);
  if (exact) return { client: exact, navigate: false };

  const sameOrigin = clients.find((client) => {
    try {
      return new URL(client.url).origin === origin;
    } catch {
      return false;
    }
  });
  if (sameOrigin) return { client: sameOrigin, navigate: true };

  return undefined;
};
