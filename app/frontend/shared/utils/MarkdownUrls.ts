// Anything but http(s) and same-origin paths - javascript: above all - is not
// a link in user-written markdown. `//host` and `/\host`
// are another origin (browsers read a backslash as a slash there), so a path
// may not start so. Whitespace and control characters are refused outright:
// browsers drop some of them while parsing, which would let `/<tab>/host`
// arrive as `//host`.
const SAME_ORIGIN_PATH = /^\/(?![/\\])/;

const UNSAFE_CHARACTER = /[\u0000-\u0020\u007f-\u009f\u2028\u2029]/;

export const isSafeMarkdownHref = (url: string) =>
  !UNSAFE_CHARACTER.test(url) &&
  (/^https?:\/\//i.test(url) || SAME_ORIGIN_PATH.test(url));

const originOf = (url: string | undefined) => {
  if (!url) return undefined;

  try {
    return new URL(url).origin;
  } catch {
    return undefined;
  }
};

// Images come only from where the page's content security policy lets them
// load: Fleetyards itself -- uploads are served from the API host -- and RSI.
// Any other host would be blocked by the browser, and would hand every reader's
// address to whoever runs it.
const imageOrigins = () =>
  new Set(
    [window.FRONTEND_ENDPOINT, window.API_ENDPOINT, window.RSI_ENDPOINT]
      .map(originOf)
      .filter(Boolean),
  );

export const isSafeMarkdownSrc = (url: string) => {
  if (UNSAFE_CHARACTER.test(url)) return false;
  if (SAME_ORIGIN_PATH.test(url)) return true;

  // The origin alone would let `blob:https://fleetyards.net/…` through, which
  // has the page's origin but is no address on it.
  if (!/^https?:\/\//i.test(url)) return false;

  const origin = originOf(url);

  return !!origin && imageOrigins().has(origin);
};
