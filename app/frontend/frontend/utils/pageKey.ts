import type { RouteLocationNormalizedLoaded } from "vue-router";

const withoutTrailingSlash = (path: string) => path.replace(/\/$/, "");

/*
 * The key the app's router-view mounts a page under. A new key throws the page
 * away and builds it again, so two URLs that are one page have to share it.
 *
 * `/compare` and `/compare/` are one page: route records are declared with a
 * trailing slash, so a link without one lands on the unslashed path and the
 * first `router.replace` a filter makes canonicalises it.
 *
 * The tabs of an editor are one page too. Keyed on the tab's own path, a tab
 * switch rebuilt the editor around it, and a form spanning its tabs lost
 * everything typed on the others.
 */
export const pageKey = (
  route: Pick<RouteLocationNormalizedLoaded, "path" | "matched">,
) => {
  const path = withoutTrailingSlash(route.path);
  const tab = route.matched[route.matched.length - 1];
  const editor = route.matched[route.matched.length - 2];

  if (tab?.meta.nav !== "editTabs" || !editor) {
    return path;
  }

  const tabSegment = withoutTrailingSlash(
    tab.path.slice(editor.path.length),
  ).replace(/^\//, "");

  return tabSegment && path.endsWith(`/${tabSegment}`)
    ? path.slice(0, -(tabSegment.length + 1))
    : path;
};
