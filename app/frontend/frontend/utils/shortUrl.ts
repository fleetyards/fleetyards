// A link on the short domain, or undefined where none is configured so the
// caller can fall back to the page's own address.
export const shortUrl = (path: string, search = "") => {
  if (!window.SHORT_DOMAIN) {
    return undefined;
  }

  return `${window.location.protocol}//${window.SHORT_DOMAIN}${path}${search}`;
};
