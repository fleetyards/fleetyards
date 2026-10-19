// Route records are declared with a trailing slash and matched loosely, so
// `/ships` and `/ships/` are one page.
export const withoutTrailingSlash = (path: string) => path.replace(/\/$/, "");
