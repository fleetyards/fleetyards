// Anything but http(s) and same-origin paths - javascript: above all - is not
// a link or an image source in user-written markdown. `//host` and `/\host`
// are another origin (browsers read a backslash as a slash there), so a path
// may not start so.
const SAME_ORIGIN_PATH = /^\/(?![/\\])/;

export const isSafeMarkdownHref = (url: string) =>
  /^https?:\/\//i.test(url) || SAME_ORIGIN_PATH.test(url);

export const isSafeMarkdownSrc = (url: string) =>
  /^https:\/\//i.test(url) || SAME_ORIGIN_PATH.test(url);
