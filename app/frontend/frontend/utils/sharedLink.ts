export type SharedFields = {
  title?: string;
  text?: string;
  url?: string;
};

export type SharedLinkTarget =
  | { kind: "route"; path: string }
  | { kind: "short"; href: string }
  | { kind: "search"; query: string }
  | { kind: "home" };

type Hosts = {
  frontendEndpoint: string;
  shortDomain?: string;
};

// Punctuation a sentence puts after a link belongs to the sentence, not the URL.
const URL_PATTERN = /https?:\/\/[^\s<>"']+?(?=[.,;:!?)\]]*(?:\s|$))/gi;

const SHARE_PATH = /^\/share(\/|$)/;

const parseUrl = (value: string): URL | undefined => {
  try {
    const url = new URL(value.trim());
    return ["http:", "https:"].includes(url.protocol) ? url : undefined;
  } catch {
    return undefined;
  }
};

const urlsIn = (value?: string): string[] => value?.match(URL_PATTERN) || [];

// Android puts a shared link in `url`, `text` or both, depending on the app it
// was shared from, and some apps add the page title around it in `text`.
export const resolveSharedLink = (
  fields: SharedFields,
  { frontendEndpoint, shortDomain }: Hosts,
): SharedLinkTarget => {
  const frontendHost = parseUrl(frontendEndpoint)?.host;
  const candidates = [
    fields.url,
    ...urlsIn(fields.text),
    ...urlsIn(fields.title),
  ];

  for (const candidate of candidates) {
    const url = candidate ? parseUrl(candidate) : undefined;
    if (!url) {
      continue;
    }

    if (url.host === frontendHost) {
      if (SHARE_PATH.test(url.pathname)) {
        return { kind: "home" };
      }

      return { kind: "route", path: `${url.pathname}${url.search}${url.hash}` };
    }

    // A short link is resolved by the server, which knows the fleets, events
    // and compare codes it points at.
    if (shortDomain && url.host === shortDomain) {
      return { kind: "short", href: url.href };
    }
  }

  const query = [fields.text, fields.title]
    .map((value) => value?.replace(URL_PATTERN, "").trim())
    .find(Boolean);

  return query ? { kind: "search", query } : { kind: "home" };
};
