export type LedgerTab = "stock" | "log";

/*
 * Which view of an inventory is open, held in the query so it can be linked to
 * without the page being rebuilt to reach it: `App.vue` keys the page on its
 * path, so a tab with a path of its own threw the whole view away and built it
 * again on every switch -- losing the scroll position and anything else the
 * page was holding.
 *
 * This was `?tab=log` once before and was moved to a route because
 * `useFilters#getQuery` spread the whole query into `q`, and the query schemas
 * are `additionalProperties: false` -- so the key reached the API as an unknown
 * filter and came back a 400. `useFilters` knows the view-state keys now and
 * drops them, which is what makes this safe.
 */
export const useLedgerTab = () => {
  const route = useRoute();
  const router = useRouter();

  const activeTab = computed<LedgerTab>({
    get: () => (route.query.tab === "log" ? "log" : "stock"),
    set: (tab) => {
      if (activeTab.value === tab) return;

      const query = { ...route.query };
      // The page number belongs to the list it was counted on: page three of
      // the log is not page three of the stock.
      delete query.page;

      if (tab === "log") {
        query.tab = "log";
      } else {
        delete query.tab;
      }

      void router.replace({ query });
    },
  });

  return { activeTab };
};
