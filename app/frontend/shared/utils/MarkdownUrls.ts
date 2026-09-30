// Anything but http(s) and same-origin paths - javascript: above all - is not
// a link or an image source in user-written markdown. `//host` and `/\host`
// are another origin (browsers read a backslash as a slash there), so a path
// may not start so. Whitespace and control characters are refused outright:
// browsers drop some of them while parsing, which would let `/<tab>/host`
// arrive as `//host`.
const SAME_ORIGIN_PATH = /^\/(?![/\\])/;

const UNSAFE_CHARACTER = /[\u0000-\u0020\u007f-\u009f\u2028\u2029]/;

export const isSafeMarkdownHref = (url: string) =>
  !UNSAFE_CHARACTER.test(url) &&
  (/^https?:\/\//i.test(url) || SAME_ORIGIN_PATH.test(url));

export const isSafeMarkdownSrc = (url: string) =>
  !UNSAFE_CHARACTER.test(url) &&
  (/^https:\/\//i.test(url) || SAME_ORIGIN_PATH.test(url));
